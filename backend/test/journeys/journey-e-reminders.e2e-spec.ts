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
 * Journey E — Reminder creation (XOR), ownership, dan sinkronisasi status
 * (`03-technical-spec.md` §3.2 & §4.5, `04-architecture-security-testing.md` §14.2).
 */
describe('Journey E — Reminder Lifecycle (e2e)', () => {
  let app: Awaited<ReturnType<typeof createJourneyApp>>;
  let userA: Awaited<ReturnType<typeof registerJourneyUser>>;
  let userB: Awaited<ReturnType<typeof registerJourneyUser>>;

  let taskId = '';
  let eventId = '';
  let reminderId = '';
  let eventReminderId = '';

  const futureIso = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const laterIso = new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString();
  const pastIso = new Date(Date.now() - 60 * 60 * 1000).toISOString();

  beforeAll(async () => {
    app = await createJourneyApp({ disableThrottle: true });
    userA = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-e-a') });
    userB = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-e-b') });

    const task = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Target task untuk reminder', dueAt: futureIso })
      .expect(201);
    taskId = task.body.data.id as string;

    const event = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Target event untuk reminder',
        startsAt: futureIso,
        endsAt: laterIso,
      })
      .expect(201);
    eventId = event.body.data.id as string;
  });

  afterAll(async () => {
    await cleanupJourneyUsers(app.prisma, 'journey-e');
    await app.app.close();
  });

  it('E1 — membuat reminder untuk task milik sendiri menghasilkan SCHEDULED + ringkasan target', async () => {
    const response = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ taskId, remindAt: futureIso });

    expectApiSuccess(response, 201, 'E1 create reminder');
    expect(response.body.data.status).toBe('SCHEDULED');
    expect(response.body.data.channel).toBe('LOCAL');
    expect(response.body.data.task.id).toBe(taskId);
    expect(response.body.data.task.title).toBe('Target task untuk reminder');
    expect(response.body.data.event).toBeNull();
    reminderId = response.body.data.id as string;
  });

  it('E2 — XOR target dijaga: tanpa target maupun dua target ditolak 400', async () => {
    const withoutTarget = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ remindAt: futureIso });
    expectApiError(
      withoutTarget,
      400,
      'REMINDER_TARGET_XOR_VIOLATION',
      'E2 without target',
    );

    const bothTargets = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ taskId, eventId, remindAt: futureIso });
    expectApiError(
      bothTargets,
      400,
      'REMINDER_TARGET_XOR_VIOLATION',
      'E2 both targets',
    );
  });

  it('E3 — target milik user lain ditolak 404 dan reminder user A tidak bisa diubah user B', async () => {
    const foreignTask = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userB.accessToken))
      .send({ title: 'Task milik user B', dueAt: futureIso })
      .expect(201);

    const crossCreate = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ taskId: foreignTask.body.data.id, remindAt: futureIso });
    expectApiError(crossCreate, 404, 'RESOURCE_NOT_FOUND', 'E3 cross-tenant create');

    const crossUpdate = await request(app.server)
      .patch(`/api/v1/reminders/${reminderId}`)
      .set('Authorization', bearer(userB.accessToken))
      .send({ status: 'CANCELLED' });
    expectApiError(crossUpdate, 404, 'RESOURCE_NOT_FOUND', 'E3 cross-tenant update');

    const crossDelete = await request(app.server)
      .delete(`/api/v1/reminders/${reminderId}`)
      .set('Authorization', bearer(userB.accessToken));
    expectApiError(crossDelete, 404, 'RESOURCE_NOT_FOUND', 'E3 cross-tenant delete');

    const listB = await request(app.server)
      .get('/api/v1/reminders')
      .set('Authorization', bearer(userB.accessToken))
      .expect(200);
    expect(listB.body.data).toHaveLength(0);
  });

  it('E4 — composite FK PostgreSQL menolak reminder yang menunjuk task user lain', async () => {
    const foreignTask = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userB.accessToken))
      .send({ title: 'Task lintas tenant', dueAt: futureIso })
      .expect(201);

    await expect(
      app.prisma.$executeRawUnsafe(
        `INSERT INTO reminders (id, user_id, task_id, remind_at, channel, status, created_at, updated_at)
         VALUES (gen_random_uuid(), $1::uuid, $2::uuid, now(), 'LOCAL', 'SCHEDULED', now(), now())`,
        userA.id,
        foreignTask.body.data.id,
      ),
    ).rejects.toThrow();
  });

  it('E5 — remindAt harus di masa depan (400 INVALID_REMINDER_TIME)', async () => {
    const response = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ taskId, remindAt: pastIso });
    expectApiError(response, 400, 'INVALID_REMINDER_TIME', 'E5 past remindAt');
  });

  it('E6 — PATCH remindAt ke masa depan otomatis mengembalikan status SCHEDULED', async () => {
    const response = await request(app.server)
      .patch(`/api/v1/reminders/${reminderId}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ remindAt: laterIso });

    expectApiSuccess(response, 200, 'E6 reschedule');
    expect(response.body.data.status).toBe('SCHEDULED');
    expect(new Date(response.body.data.remindAt).toISOString()).toBe(
      new Date(laterIso).toISOString(),
    );
  });

  it('E7 — klien dapat menandai status SENT, FAILED, dan CANCELLED', async () => {
    for (const status of ['SENT', 'FAILED', 'CANCELLED'] as const) {
      const response = await request(app.server)
        .patch(`/api/v1/reminders/${reminderId}`)
        .set('Authorization', bearer(userA.accessToken))
        .send({ status });
      expectApiSuccess(response, 200, `E7 status ${status}`);
      expect(response.body.data.status).toBe(status);
    }
  });

  it('E8 — task DONE membatalkan seluruh reminder SCHEDULED milik task tersebut', async () => {
    const task = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Task yang akan selesai', dueAt: futureIso })
      .expect(201);
    const doneTaskId = task.body.data.id as string;

    const first = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ taskId: doneTaskId, remindAt: futureIso })
      .expect(201);
    const second = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ taskId: doneTaskId, remindAt: laterIso })
      .expect(201);

    await request(app.server)
      .patch(`/api/v1/tasks/${doneTaskId}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ status: 'DONE' })
      .expect(200);

    const scheduled = await request(app.server)
      .get('/api/v1/reminders?status=SCHEDULED')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    const scheduledIds = (scheduled.body.data as { id: string }[]).map(
      (item) => item.id,
    );
    expect(scheduledIds).not.toContain(first.body.data.id);
    expect(scheduledIds).not.toContain(second.body.data.id);

    const all = await request(app.server)
      .get('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    const cancelled = (all.body.data as { id: string; status: string }[]).filter(
      (item) =>
        item.id === first.body.data.id || item.id === second.body.data.id,
    );
    expect(cancelled).toHaveLength(2);
    expect(cancelled.every((item) => item.status === 'CANCELLED')).toBe(true);
  });

  it('E9 — menghapus event menghapus reminder terkait (ON DELETE CASCADE)', async () => {
    const created = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ eventId, remindAt: futureIso })
      .expect(201);
    eventReminderId = created.body.data.id as string;

    await request(app.server)
      .delete(`/api/v1/calendar/events/${eventId}`)
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);

    const remaining = await app.prisma.reminder.findUnique({
      where: { id: eventReminderId },
    });
    expect(remaining).toBeNull();
  });

  it('E10 — daftar reminder diurutkan remindAt ASC dan filter status bekerja', async () => {
    const list = await request(app.server)
      .get('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);

    const remindAts = (list.body.data as { remindAt: string }[]).map(
      (item) => new Date(item.remindAt).getTime(),
    );
    const sorted = [...remindAts].sort((a, b) => a - b);
    expect(remindAts).toEqual(sorted);

    const cancelledOnly = await request(app.server)
      .get('/api/v1/reminders?status=CANCELLED')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(
      (cancelledOnly.body.data as { status: string }[]).every(
        (item) => item.status === 'CANCELLED',
      ),
    ).toBe(true);
  });

  it('E11 — menghapus reminder mengembalikan 200 dan idempoten 404 setelahnya', async () => {
    const created = await request(app.server)
      .post('/api/v1/reminders')
      .set('Authorization', bearer(userA.accessToken))
      .send({ taskId, remindAt: futureIso })
      .expect(201);
    const createdId = created.body.data.id as string;

    const deleted = await request(app.server)
      .delete(`/api/v1/reminders/${createdId}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiSuccess(deleted, 200, 'E11 delete reminder');
    expect(deleted.body.data.deleted).toBe(true);

    const again = await request(app.server)
      .delete(`/api/v1/reminders/${createdId}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiError(again, 404, 'RESOURCE_NOT_FOUND', 'E11 delete twice');
  });
});
