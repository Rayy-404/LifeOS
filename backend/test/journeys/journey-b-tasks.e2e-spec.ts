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
 * Journey B — Task CRUD + status lifecycle + filter/search
 * (`03-technical-spec.md` §4.2, `04-architecture-security-testing.md` §14.2).
 */
describe('Journey B — Task Lifecycle (e2e)', () => {
  let app: Awaited<ReturnType<typeof createJourneyApp>>;
  let userA: Awaited<ReturnType<typeof registerJourneyUser>>;
  let userB: Awaited<ReturnType<typeof registerJourneyUser>>;

  let taskId = '';
  let dueTaskId = '';

  beforeAll(async () => {
    app = await createJourneyApp({ disableThrottle: true });
    userA = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-b-a') });
    userB = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-b-b') });
  });

  afterAll(async () => {
    await cleanupJourneyUsers(app.prisma, 'journey-b');
    await app.app.close();
  });

  it('B1 — membuat tugas baru memakai default status TODO dan completedAt kosong', async () => {
    const response = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Menyelesaikan proyek Flutter',
        description: 'Implementasi task manager',
        priority: 'HIGH',
        dueAt: '2026-10-20T12:00:00.000Z',
      });

    expectApiSuccess(response, 201, 'B1 create task');
    expect(response.body.data.title).toBe('Menyelesaikan proyek Flutter');
    expect(response.body.data.status).toBe('TODO');
    expect(response.body.data.priority).toBe('HIGH');
    expect(response.body.data.completedAt).toBeNull();
    expect(response.body.data.reminders).toEqual([]);
    taskId = response.body.data.id as string;
  });

  it('B2 — filter status/priority/search hanya mengembalikan task yang cocok', async () => {
    await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Tugas lowercase tanpa prioritas', priority: 'LOW' })
      .expect(201);

    const filtered = await request(app.server)
      .get('/api/v1/tasks?status=TODO&priority=HIGH&search=flutter')
      .set('Authorization', bearer(userA.accessToken));

    expectApiSuccess(filtered, 200, 'B2 filtered list');
    expect(filtered.body.data).toHaveLength(1);
    expect(filtered.body.data[0].id).toBe(taskId);
    expect(filtered.body.meta.totalItems).toBe(1);

    const lowPriority = await request(app.server)
      .get('/api/v1/tasks?priority=LOW')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(lowPriority.body.data).toHaveLength(1);
  });

  it('B3 — pagination meta konsisten dengan jumlah data', async () => {
    const response = await request(app.server)
      .get('/api/v1/tasks?page=1&limit=1')
      .set('Authorization', bearer(userA.accessToken));

    expectApiSuccess(response, 200, 'B3 pagination');
    expect(response.body.data).toHaveLength(1);
    expect(response.body.meta.page).toBe(1);
    expect(response.body.meta.limit).toBe(1);
    expect(response.body.meta.totalItems).toBe(2);
    expect(response.body.meta.totalPages).toBe(2);
  });

  it('B4 — filter rentang tanggal memakai dueAt dengan batas [start, end)', async () => {
    await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Tugas dengan deadline Regardless',
        dueAt: '2026-10-25T09:00:00.000Z',
      })
      .expect(201);

    const inRange = await request(app.server)
      .get('/api/v1/tasks?from=2026-10-19&to=2026-10-20')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(inRange.body.data.map((t: { id: string }) => t.id)).toEqual([taskId]);

    const outOfRange = await request(app.server)
      .get('/api/v1/tasks?from=2026-10-21&to=2026-10-31')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(outOfRange.body.data).toHaveLength(1);
    expect(outOfRange.body.data[0].title).toBe('Tugas dengan deadline Regardless');
  });

  it('B5 — status DONE mengisi completedAt dan reopen mengosongkannya', async () => {
    const done = await request(app.server)
      .patch(`/api/v1/tasks/${taskId}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ status: 'DONE' });

    expectApiSuccess(done, 200, 'B5 done');
    expect(done.body.data.status).toBe('DONE');
    expect(done.body.data.completedAt).toEqual(expect.any(String));

    const reopened = await request(app.server)
      .patch(`/api/v1/tasks/${taskId}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({ status: 'TODO' });

    expectApiSuccess(reopened, 200, 'B5 reopen');
    expect(reopened.body.data.status).toBe('TODO');
    expect(reopened.body.data.completedAt).toBeNull();
  });

  it('B6 — menghapus tugas mengembalikan 200 dan thereafter 404', async () => {
    const created = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Tugas yang akan dihapus' })
      .expect(201);
    const createdId = created.body.data.id as string;

    const deleted = await request(app.server)
      .delete(`/api/v1/tasks/${createdId}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiSuccess(deleted, 200, 'B6 delete');
    expect(deleted.body.data.deleted).toBe(true);

    const afterDelete = await request(app.server)
      .get(`/api/v1/tasks/${createdId}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiError(afterDelete, 404, 'RESOURCE_NOT_FOUND', 'B6 get after delete');
  });

  it('B7 — Zero IDOR: user B tidak dapat membaca, mengubah, atau menghapus task user A', async () => {
    const read = await request(app.server)
      .get(`/api/v1/tasks/${taskId}`)
      .set('Authorization', bearer(userB.accessToken));
    expectApiError(read, 404, 'RESOURCE_NOT_FOUND', 'B7 cross-tenant read');

    const update = await request(app.server)
      .patch(`/api/v1/tasks/${taskId}`)
      .set('Authorization', bearer(userB.accessToken))
      .send({ title: 'Dibajak' });
    expectApiError(update, 404, 'RESOURCE_NOT_FOUND', 'B7 cross-tenant update');

    const remove = await request(app.server)
      .delete(`/api/v1/tasks/${taskId}`)
      .set('Authorization', bearer(userB.accessToken));
    expectApiError(remove, 404, 'RESOURCE_NOT_FOUND', 'B7 cross-tenant delete');

    const list = await request(app.server)
      .get('/api/v1/tasks')
      .set('Authorization', bearer(userB.accessToken))
      .expect(200);
    expect(list.body.data).toHaveLength(0);
  });

  it('B8 — payload tidak valid ditolak dengan 400 VALIDATION_ERROR', async () => {
    const emptyTitle = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: '' });
    expectApiError(emptyTitle, 400, 'VALIDATION_ERROR', 'B8 empty title');

    const unknownField = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Valid', unexpectedField: 'boom' });
    expectApiError(unknownField, 400, 'VALIDATION_ERROR', 'B8 unknown field');

    const invalidPriority = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Valid', priority: 'URGENT' });
    expectApiError(invalidPriority, 400, 'VALIDATION_ERROR', 'B8 invalid priority');

    const invalidDueAt = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Valid', dueAt: 'besok' });
    expectApiError(invalidDueAt, 400, 'VALIDATION_ERROR', 'B8 invalid dueAt');
  });

  it('B9 — daftar diurutkan berdasarkan dueAt ASC dengan task tanpa deadline di akhir', async () => {
    const withoutDue = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({ title: 'Tanpa deadline' })
      .expect(201);
    dueTaskId = withoutDue.body.data.id as string;

    const list = await request(app.server)
      .get('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);

    const items = list.body.data as { id: string; dueAt: string | null }[];
    const firstWithoutDue = items.findIndex((item) => item.dueAt === null);
    expect(firstWithoutDue).toBeGreaterThan(0);
    expect(items.slice(firstWithoutDue).every((item) => item.dueAt === null)).toBe(
      true,
    );
    expect(items.map((item) => item.id)).toContain(dueTaskId);
  });
});
