import * as request from 'supertest';
import { DateRangeHelper } from '../../src/common/utils/date-range.helper';
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
 * Journey C — Habit creation (activeDays) + idempotent check-in + streak
 * (`03-technical-spec.md` §4.3, `04-architecture-security-testing.md` §14.2).
 */
describe('Journey C — Habit & Check-in (e2e)', () => {
  let app: Awaited<ReturnType<typeof createJourneyApp>>;
  let userA: Awaited<ReturnType<typeof registerJourneyUser>>;
  let userB: Awaited<ReturnType<typeof registerJourneyUser>>;

  const today = DateRangeHelper.getTodayLocalDateString('Asia/Jakarta');
  const yesterday = DateRangeHelper.addDaysToDateString(today, -1);
  const tomorrow = DateRangeHelper.addDaysToDateString(today, 1);
  const tooOld = DateRangeHelper.addDaysToDateString(today, -8);
  const todayIso = DateRangeHelper.getIsoWeekday(today);
  const yesterdayIso = DateRangeHelper.getIsoWeekday(yesterday);

  beforeAll(async () => {
    app = await createJourneyApp({ disableThrottle: true });
    userA = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-c-a') });
    userB = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-c-b') });
  });

  afterAll(async () => {
    await cleanupJourneyUsers(app.prisma, 'journey-c');
    await app.app.close();
  });

  it('C1 — membuat habit dengan activeDays valid', async () => {
    const response = await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Membaca', activeDays: [1, 3, 5] });

    expectApiSuccess(response, 201, 'C1 create habit');
    expect(response.body.data.name).toBe('Membaca');
    expect(response.body.data.activeDays).toEqual([1, 3, 5]);
    expect(response.body.data.isActive).toBe(true);
    expect(response.body.data.currentStreak).toBe(0);
    expect(response.body.data.completedToday).toBe(false);
  });

  it('C2 — activeDays tidak valid ditolak dengan 400 VALIDATION_ERROR', async () => {
    const invalidPayloads = [
      { label: 'kosong', activeDays: [] },
      { label: 'nol', activeDays: [0] },
      { label: 'delapan', activeDays: [8] },
      { label: 'duplikat', activeDays: [1, 1, 3] },
    ];

    for (const payload of invalidPayloads) {
      const response = await request(app.server)
        .post('/api/v1/habits')
        .set('Authorization', bearer(userA.accessToken))
        .send({ name: 'Habit invalid', activeDays: payload.activeDays });
      expectApiError(response, 400, 'VALIDATION_ERROR', `C2 activeDays ${payload.label}`);
    }
  });

  it('C3 — CHECK constraint PostgreSQL menolak active_days di luar 1..7 dan duplikat', async () => {
    await expect(
      app.prisma.$executeRawUnsafe(
        `INSERT INTO habits (id, user_id, name, is_active, active_days, created_at, updated_at)
         VALUES (gen_random_uuid(), $1::uuid, 'invalid-days', true, ARRAY[9]::int[], now(), now())`,
        userA.id,
      ),
    ).rejects.toThrow();

    await expect(
      app.prisma.$executeRawUnsafe(
        `INSERT INTO habits (id, user_id, name, is_active, active_days, created_at, updated_at)
         VALUES (gen_random_uuid(), $1::uuid, 'duplicate-days', true, ARRAY[1,1]::int[], now(), now())`,
        userA.id,
      ),
    ).rejects.toThrow();

    const stored = await app.prisma.habit.count({
      where: { userId: userA.id, name: { in: ['invalid-days', 'duplicate-days'] } },
    });
    expect(stored).toBe(0);
  });

  it('C4 — check-in idempoten: PUT 3x untuk tanggal sama hanya menghasilkan 1 baris log', async () => {
    const habit = await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Idempoten', activeDays: [todayIso] })
      .expect(201);
    const habitId = habit.body.data.id as string;

    for (let attempt = 0; attempt < 3; attempt += 1) {
      const response = await request(app.server)
        .put(`/api/v1/habits/${habitId}/logs/${today}`)
        .set('Authorization', bearer(userA.accessToken))
        .send({ completed: true });
      expectApiSuccess(response, 200, `C4 check-in attempt ${attempt + 1}`);
    }

    const logRows = await app.prisma.habitLog.count({
      where: { habitId, logDate: new Date(`${today}T00:00:00.000Z`) },
    });
    expect(logRows).toBe(1);

    const logs = await request(app.server)
      .get(`/api/v1/habits/${habitId}/logs?from=${today}&to=${today}`)
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(logs.body.data).toHaveLength(1);
  });

  it('C5 — currentStreak menghitung log berurutan dan mengabaikan hari non-aktif', async () => {
    const habit = await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Streak habits', activeDays: [yesterdayIso, todayIso] })
      .expect(201);
    const habitId = habit.body.data.id as string;

    await request(app.server)
      .put(`/api/v1/habits/${habitId}/logs/${yesterday}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ completed: true })
      .expect(200);
    await request(app.server)
      .put(`/api/v1/habits/${habitId}/logs/${today}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ completed: true })
      .expect(200);

    const detail = await request(app.server)
      .get(`/api/v1/habits/${habitId}`)
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(detail.body.data.currentStreak).toBe(2);
    expect(detail.body.data.completedToday).toBe(true);

    const untouched = await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Belum check-in', activeDays: [todayIso] })
      .expect(201);
    const untouchedDetail = await request(app.server)
      .get(`/api/v1/habits/${untouched.body.data.id}`)
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(untouchedDetail.body.data.currentStreak).toBe(0);
    expect(untouchedDetail.body.data.completedToday).toBe(false);
  });

  it('C6 — check-in tanggal mendatang ditolak dan backfill terlalu lama ditolak', async () => {
    const habit = await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Batas check-in', activeDays: [1, 2, 3, 4, 5, 6, 7] })
      .expect(201);
    const habitId = habit.body.data.id as string;

    const future = await request(app.server)
      .put(`/api/v1/habits/${habitId}/logs/${tomorrow}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ completed: true });
    expectApiError(
      future,
      400,
      'FUTURE_HABIT_LOG_NOT_ALLOWED',
      'C6 future log',
    );

    const tooOldLog = await request(app.server)
      .put(`/api/v1/habits/${habitId}/logs/${tooOld}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ completed: true });
    expectApiError(tooOldLog, 400, 'VALIDATION_ERROR', 'C6 too old backfill');
  });

  it('C7 — menghapus habit menghapus log terkait (cascade) dan idempoten', async () => {
    const habit = await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Temporary', activeDays: [todayIso] })
      .expect(201);
    const habitId = habit.body.data.id as string;

    await request(app.server)
      .put(`/api/v1/habits/${habitId}/logs/${today}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ completed: true })
      .expect(200);

    const deleted = await request(app.server)
      .delete(`/api/v1/habits/${habitId}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiSuccess(deleted, 200, 'C7 delete habit');
    expect(deleted.body.data.deleted).toBe(true);

    const logsLeft = await app.prisma.habitLog.count({ where: { habitId } });
    expect(logsLeft).toBe(0);
  });

  it('C8 — Zero IDOR: user B tidak dapat membaca, mengubah, atau check-in habit user A', async () => {
    const habit = await request(app.server)
      .post('/api/v1/habits')
      .set('Authorization', bearer(userA.accessToken))
      .send({ name: 'Milik A', activeDays: [1, 2, 3, 4, 5, 6, 7] })
      .expect(201);
    const habitId = habit.body.data.id as string;

    const read = await request(app.server)
      .get(`/api/v1/habits/${habitId}`)
      .set('Authorization', bearer(userB.accessToken));
    expectApiError(read, 404, 'RESOURCE_NOT_FOUND', 'C8 cross-tenant read');

    const update = await request(app.server)
      .patch(`/api/v1/habits/${habitId}`)
      .set('Authorization', bearer(userB.accessToken))
      .send({ name: 'Dibajak' });
    expectApiError(update, 404, 'RESOURCE_NOT_FOUND', 'C8 cross-tenant update');

    const checkIn = await request(app.server)
      .put(`/api/v1/habits/${habitId}/logs/${today}`)
      .set('Authorization', bearer(userB.accessToken))
      .send({ completed: true });
    expectApiError(checkIn, 404, 'RESOURCE_NOT_FOUND', 'C8 cross-tenant check-in');

    const logs = await request(app.server)
      .get(`/api/v1/habits/${habitId}/logs`)
      .set('Authorization', bearer(userB.accessToken));
    expectApiError(logs, 404, 'RESOURCE_NOT_FOUND', 'C8 cross-tenant logs');

    const list = await request(app.server)
      .get('/api/v1/habits')
      .set('Authorization', bearer(userB.accessToken))
      .expect(200);
    expect(list.body.data).toHaveLength(0);
  });
});
