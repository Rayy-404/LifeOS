import * as request from 'supertest';
import { createJourneyApp } from '../support/journey-app';
import {
  expectApiError,
  expectApiSuccess,
} from '../support/journey-assertions';
import {
  bearer,
  cleanupJourneyUsers,
  registerJourneyUser,
  uniqueJourneyEmail,
} from '../support/journey-fixtures';

/**
 * Journey F — Dashboard hari ini + statistik overview/weekly yang diverifikasi
 * terhadap query SQL manual + isolasi data antar user
 * (`03-technical-spec.md` §4.6, `04-architecture-security-testing.md` §14.2).
 *
 * Perhitungan interval pada suite ini sengaja TIDAK memakai `DateRangeHelper`
 * aplikasi, melainkan offset waktu tetap (`+07:00` untuk Asia/Jakarta) agar
 * menjadi pembanding yang benar-benar independen.
 */
describe('Journey F — Dashboard, Statistics & Isolation (e2e)', () => {
  let app: Awaited<ReturnType<typeof createJourneyApp>>;
  let userA: Awaited<ReturnType<typeof registerJourneyUser>>;
  let userB: Awaited<ReturnType<typeof registerJourneyUser>>;
  let emptyUser: Awaited<ReturnType<typeof registerJourneyUser>>;

  const JAKARTA_OFFSET = '+07:00';

  const todayKey = new Date(Date.now() + 7 * 60 * 60 * 1000)
    .toISOString()
    .slice(0, 10);
  const shiftDate = (dateKey: string, days: number): string => {
    const base = new Date(`${dateKey}T00:00:00.000Z`);
    base.setUTCDate(base.getUTCDate() + days);
    return base.toISOString().slice(0, 10);
  };
  const todayStartUtc = new Date(`${todayKey}T00:00:00.000${JAKARTA_OFFSET}`);
  const noonToday = new Date(todayStartUtc.getTime() + 12 * 60 * 60 * 1000);
  const noonYesterday = new Date(
    todayStartUtc.getTime() - 12 * 60 * 60 * 1000,
  );

  beforeAll(async () => {
    app = await createJourneyApp({ disableThrottle: true });
    userA = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-f-a') });
    userB = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-f-b') });
    emptyUser = await registerJourneyUser(app.server, {
      email: uniqueJourneyEmail('journey-f-empty'),
    });

    // Task jatuh tempo hari ini (TODO) -> pending. DueAt memakai ujung hari
    // lokal agar tidak berubah menjadi overdue bila suite berjalan setelah
    // tengah hari.
    await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Tugas jatuh tempo hari ini',
        dueAt: new Date(todayStartUtc.getTime() + 24 * 60 * 60 * 1000 - 1).toISOString(),
      })
      .expect(201);

    // Task selesai hari ini -> completed
    await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Tugas selesai hari ini',
        status: 'DONE',
        dueAt: noonToday.toISOString(),
      })
      .expect(201);

    // Task lewat tenggat (kemarin) -> overdue
    await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Tugas lewat tenggat', dueAt: noonYesterday.toISOString() })
      .expect(201);

    // Task tanpa tenggat -> pending (backlog)
    await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Tugas backlog tanpa tenggat' })
      .expect(201);

    // Habit harian + check-in hari ini
    const habit = await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Habit harian statistik', activeDays: [1, 2, 3, 4, 5, 6, 7] })
      .expect(201);
    await request(app.server)
      .put(`/api/v1/habits/${habit.body.data.id}/logs/${todayKey}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ completed: true })
      .expect(200);

    // Habit pada hari kerja saja (Senin/Selasa/Rabu/Kamis/Jumat)
    await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Habit hari kerja', activeDays: [1, 2, 3, 4, 5] })
      .expect(201);

    // Agenda hari ini
    await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Agenda hari ini',
        startsAt: noonToday.toISOString(),
        endsAt: new Date(noonToday.getTime() + 60 * 60 * 1000).toISOString(),
      })
      .expect(201);
  });

  afterAll(async () => {
    await cleanupJourneyUsers(app.prisma, 'journey-f');
    await app.app.close();
  });

  it('F1 — dashboard hari ini reflects data task, habit, dan agenda yang sebenarnya', async () => {
    const isoWeekday =
      new Date(`${todayKey}T00:00:00.000Z`).getUTCDay() === 0
        ? 7
        : new Date(`${todayKey}T00:00:00.000Z`).getUTCDay();
    const expectedScheduledHabits = isoWeekday <= 5 ? 2 : 1;

    const response = await request(app.server)
      .get(`/api/v1/dashboard/today?date=${todayKey}`)
      .set('Authorization', bearer(userA.accessToken));

    expectApiSuccess(response, 200, 'F1 dashboard');
    expect(response.body.data.date).toBe(todayKey);
    expect(response.body.data.timezone).toBe('Asia/Jakarta');
    expect(response.body.data.tasks.completed).toBe(1);
    expect(response.body.data.tasks.pending).toBe(2);
    expect(response.body.data.tasks.overdue).toBe(1);
    expect(response.body.data.tasks.total).toBe(3);
    expect(response.body.data.habits.scheduled).toBe(expectedScheduledHabits);
    expect(response.body.data.habits.completed).toBe(1);
    expect(response.body.data.upcomingEvents).toHaveLength(1);
    expect(response.body.data.todayTasks.length).toBeGreaterThan(0);
  });

  it('F2 — statistik overview identik dengan query SQL manual', async () => {
    const from = shiftDate(todayKey, -6);
    const to = todayKey;
    const startUtc = new Date(`${from}T00:00:00.000${JAKARTA_OFFSET}`);
    const endUtc = new Date(
      new Date(`${to}T00:00:00.000${JAKARTA_OFFSET}`).getTime() +
        24 * 60 * 60 * 1000,
    );

    const response = await request(app.server)
      .get(`/api/v1/statistics/overview?from=${from}&to=${to}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiSuccess(response, 200, 'F2 statistics overview');

    const taskRows = await app.prisma.$queryRaw<
      {
        total: number;
        completed: number;
        overdue: number;
      }[]
    >`
      SELECT
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE status = 'DONE')::int AS completed,
        COUNT(*) FILTER (
          WHERE status <> 'DONE' AND due_at IS NOT NULL AND due_at < NOW()
        )::int AS overdue
      FROM tasks
      WHERE user_id = ${userA.id}::uuid
        AND (
          (due_at >= ${startUtc} AND due_at < ${endUtc}) OR
          (completed_at >= ${startUtc} AND completed_at < ${endUtc})
        )
    `;

    const scheduledRows = await app.prisma.$queryRaw<{ cnt: number }[]>`
      SELECT COUNT(*)::int AS cnt
      FROM generate_series(${from}::date, ${to}::date, '1 day') AS d
      JOIN habits h
        ON h.user_id = ${userA.id}::uuid
       AND h.is_active
       AND (EXTRACT(ISODOW FROM d)::int = ANY (h.active_days))
    `;

    const completedInstanceRows = await app.prisma.$queryRaw<{ cnt: number }[]>`
      SELECT COUNT(*)::int AS cnt
      FROM habit_logs l
      JOIN habits h
        ON h.id = l.habit_id
       AND h.user_id = ${userA.id}::uuid
       AND h.is_active
      WHERE l.log_date BETWEEN ${from}::date AND ${to}::date
        AND (EXTRACT(ISODOW FROM l.log_date)::int = ANY (h.active_days))
    `;

    expect(response.body.data.from).toBe(from);
    expect(response.body.data.to).toBe(to);
    expect(response.body.data.tasks.total).toBe(taskRows[0].total);
    expect(response.body.data.tasks.completed).toBe(taskRows[0].completed);
    expect(response.body.data.tasks.overdue).toBe(taskRows[0].overdue);
    expect(response.body.data.tasks.completionRate).toBeCloseTo(
      taskRows[0].total === 0
        ? 0
        : Math.round((taskRows[0].completed / taskRows[0].total) * 1000) / 10,
      5,
    );
    expect(response.body.data.habits.totalScheduledInstances).toBe(
      scheduledRows[0].cnt,
    );
    expect(response.body.data.habits.totalCompletedInstances).toBe(
      completedInstanceRows[0].cnt,
    );
  });

  it('F3 — statistik weekly identik dengan agregasi SQL per tanggal lokal user', async () => {
    const isoWeekday =
      new Date(`${todayKey}T00:00:00.000Z`).getUTCDay() === 0
        ? 7
        : new Date(`${todayKey}T00:00:00.000Z`).getUTCDay();
    const weekStart = shiftDate(todayKey, -(isoWeekday - 1));
    const weekEnd = shiftDate(weekStart, 6);

    const startUtc = new Date(`${weekStart}T00:00:00.000${JAKARTA_OFFSET}`);
    const endUtc = new Date(
      new Date(`${weekEnd}T00:00:00.000${JAKARTA_OFFSET}`).getTime() +
        24 * 60 * 60 * 1000,
    );

    const response = await request(app.server)
      .get(`/api/v1/statistics/weekly?weekStart=${weekStart}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiSuccess(response, 200, 'F3 statistics weekly');
    expect(response.body.data.weekStart).toBe(weekStart);
    expect(response.body.data.weekEnd).toBe(weekEnd);
    expect(response.body.data.days).toHaveLength(7);

    const taskRows = await app.prisma.$queryRaw<
      { day: string; cnt: number }[]
    >`
      SELECT (t.completed_at AT TIME ZONE u.timezone)::date::text AS day,
             COUNT(*)::int AS cnt
      FROM tasks t
      JOIN users u ON u.id = t.user_id
      WHERE t.user_id = ${userA.id}::uuid
        AND t.completed_at >= ${startUtc}
        AND t.completed_at < ${endUtc}
      GROUP BY 1
    `;

    const habitRows = await app.prisma.$queryRaw<
      { day: string; scheduled: number; completed: number }[]
    >`
      SELECT d::date::text AS day,
             COUNT(DISTINCT h.id)::int AS scheduled,
             COUNT(l.id)::int AS completed
      FROM generate_series(${weekStart}::date, ${weekEnd}::date, '1 day') AS d
      JOIN habits h
        ON h.user_id = ${userA.id}::uuid
       AND h.is_active
       AND (EXTRACT(ISODOW FROM d)::int = ANY (h.active_days))
      LEFT JOIN habit_logs l
        ON l.habit_id = h.id
       AND l.log_date = d::date
      GROUP BY 1
    `;

    const apiDays = response.body.data.days as {
      date: string;
      tasksCompleted: number;
      habitsScheduled: number;
      habitsCompleted: number;
    }[];

    for (const day of apiDays) {
      const taskRow = taskRows.find((row) => row.day === day.date);
      const habitRow = habitRows.find((row) => row.day === day.date);
      expect(day.tasksCompleted).toBe(taskRow?.cnt ?? 0);
      expect(day.habitsScheduled).toBe(habitRow?.scheduled ?? 0);
      expect(day.habitsCompleted).toBe(habitRow?.completed ?? 0);
    }
  });

  it('F4 — isolasi data antar user: user B tidak melihat data user A', async () => {
    const dashboard = await request(app.server)
      .get(`/api/v1/dashboard/today?date=${todayKey}`)
      .set('Authorization', bearer(userB.accessToken))
      .expect(200);
    expect(dashboard.body.data.tasks.total).toBe(0);
    expect(dashboard.body.data.tasks.overdue).toBe(0);
    expect(dashboard.body.data.todayTasks).toHaveLength(0);
    expect(dashboard.body.data.upcomingEvents).toHaveLength(0);

    const statistics = await request(app.server)
      .get(
        `/api/v1/statistics/overview?from=${shiftDate(todayKey, -6)}&to=${todayKey}`,
      )
      .set('Authorization', bearer(userB.accessToken))
      .expect(200);
    expect(statistics.body.data.tasks.total).toBe(0);
    expect(statistics.body.data.habits.totalScheduledInstances).toBe(0);
  });

  it('F5 — akun tanpa data menghasilkan angka nol tanpa error', async () => {
    const dashboard = await request(app.server)
      .get('/api/v1/dashboard/today')
      .set('Authorization', bearer(emptyUser.accessToken))
      .expect(200);
    expect(dashboard.body.data.tasks.total).toBe(0);
    expect(dashboard.body.data.habits.scheduled).toBe(0);

    const overview = await request(app.server)
      .get(
        `/api/v1/statistics/overview?from=${shiftDate(todayKey, -6)}&to=${todayKey}`,
      )
      .set('Authorization', bearer(emptyUser.accessToken))
      .expect(200);
    expect(overview.body.data.tasks.completionRate).toBe(0);
    expect(overview.body.data.habits.consistencyRate).toBe(0);
  });

  it('F6 — endpoint dashboard & statistik menolak request tanpa token', async () => {
    const dashboard = await request(app.server).get('/api/v1/dashboard/today');
    expectApiError(dashboard, 401, 'UNAUTHORIZED', 'F6 dashboard without token');

    const overview = await request(app.server).get(
      `/api/v1/statistics/overview?from=${shiftDate(todayKey, -6)}&to=${todayKey}`,
    );
    expectApiError(overview, 401, 'UNAUTHORIZED', 'F6 statistics without token');
  });
});
