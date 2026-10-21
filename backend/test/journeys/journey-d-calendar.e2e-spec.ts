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
 * Journey D — Calendar event creation + agenda aggregation + batas tengah malam
 * (`03-technical-spec.md` §4.4, `04-architecture-security-testing.md` §14.2).
 */
describe('Journey D — Calendar & Agenda (e2e)', () => {
  let app: Awaited<ReturnType<typeof createJourneyApp>>;
  let userA: Awaited<ReturnType<typeof registerJourneyUser>>;
  let userB: Awaited<ReturnType<typeof registerJourneyUser>>;

  let eventId = '';

  beforeAll(async () => {
    app = await createJourneyApp({ disableThrottle: true });
    userA = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-d-a') });
    userB = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-d-b') });
  });

  afterAll(async () => {
    await cleanupJourneyUsers(app.prisma, 'journey-d');
    await app.app.close();
  });

  it('D1 — membuat kegiatan terjadwal', async () => {
    const response = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Belajar pemrograman',
        description: 'Membahas arsitektur NestJS & Flutter',
        location: 'Gedung B R.204',
        startsAt: '2026-10-18T01:00:00.000Z',
        endsAt: '2026-10-18T03:00:00.000Z',
      });

    expectApiSuccess(response, 201, 'D1 create event');
    expect(response.body.data.title).toBe('Belajar pemrograman');
    expect(response.body.data.location).toBe('Gedung B R.204');
    expect(response.body.data.reminders).toEqual([]);
    eventId = response.body.data.id as string;
  });

  it('D2 — endsAt harus lebih besar dari startsAt (400 INVALID_TIME_RANGE)', async () => {
    const sameTime = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Durasi nol',
        startsAt: '2026-10-18T01:00:00.000Z',
        endsAt: '2026-10-18T01:00:00.000Z',
      });
    expectApiError(sameTime, 400, 'INVALID_TIME_RANGE', 'D2 same start/end');

    const reversed = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Durasi negatif',
        startsAt: '2026-10-18T05:00:00.000Z',
        endsAt: '2026-10-18T01:00:00.000Z',
      });
    expectApiError(reversed, 400, 'INVALID_TIME_RANGE', 'D2 reversed range');
  });

  it('D3 — agenda menggabungkan event dan task sesuai rentang', async () => {
    const task = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Menyelesaikan proyek Flutter',
        dueAt: '2026-10-18T05:00:00.000Z',
      })
      .expect(201);

    const agenda = await request(app.server)
      .get('/api/v1/calendar/events?from=2026-10-18&to=2026-10-18')
      .set('Authorization', bearer(userA.accessToken));

    expectApiSuccess(agenda, 200, 'D3 agenda');
    expect(agenda.body.data.from).toBe('2026-10-18');
    expect(agenda.body.data.to).toBe('2026-10-18');
    expect(
      agenda.body.data.events.some((e: { id: string }) => e.id === eventId),
    ).toBe(true);
    expect(
      agenda.body.data.tasks.some((t: { id: string }) => t.id === task.body.data.id),
    ).toBe(true);
    expect(agenda.body.data.events[0].type).toBe('EVENT');
    expect(agenda.body.data.tasks[0].type).toBe('TASK');
  });

  it('D4 — batas 23:59 dan 00:00 waktu lokal dihitung tepat pada tanggalnya', async () => {
    // 2026-10-18 23:30 - 23:45 WIB (UTC+7) -> 16:30Z - 16:45Z
    const lateNight = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Agenda batas malam',
        startsAt: '2026-10-18T16:30:00.000Z',
        endsAt: '2026-10-18T16:45:00.000Z',
      })
      .expect(201);

    // 2026-10-19 00:00 WIB -> 2026-10-18T17:00:00.000Z
    const midnightTask = await request(app.server)
      .post('/api/v1/tasks')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Tugas tepat tengah malam',
        dueAt: '2026-10-18T17:00:00.000Z',
      })
      .expect(201);

    const day18 = await request(app.server)
      .get('/api/v1/calendar/events?from=2026-10-18&to=2026-10-18')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(
      day18.body.data.events.filter(
        (e: { id: string }) => e.id === lateNight.body.data.id,
      ),
    ).toHaveLength(1);
    expect(
      day18.body.data.tasks.filter(
        (t: { id: string }) => t.id === midnightTask.body.data.id,
      ),
    ).toHaveLength(0);

    const day19 = await request(app.server)
      .get('/api/v1/calendar/events?from=2026-10-19&to=2026-10-19')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(
      day19.body.data.events.filter(
        (e: { id: string }) => e.id === lateNight.body.data.id,
      ),
    ).toHaveLength(0);
    expect(
      day19.body.data.tasks.filter(
        (t: { id: string }) => t.id === midnightTask.body.data.id,
      ),
    ).toHaveLength(1);

    const bothDays = await request(app.server)
      .get('/api/v1/calendar/events?from=2026-10-18&to=2026-10-19')
      .set('Authorization', bearer(userA.accessToken))
      .expect(200);
    expect(
      bothDays.body.data.events.filter(
        (e: { id: string }) => e.id === lateNight.body.data.id,
      ),
    ).toHaveLength(1);
    expect(
      bothDays.body.data.tasks.filter(
        (t: { id: string }) => t.id === midnightTask.body.data.id,
      ),
    ).toHaveLength(1);
  });

  it('D5 — memperbarui kegiatan memindahkan jadwal dan mengembalikan data terbaru', async () => {
    const response = await request(app.server)
      .patch(`/api/v1/calendar/events/${eventId}`)
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Belajar pemrograman (reschedule)',
        startsAt: '2026-10-19T01:00:00.000Z',
        endsAt: '2026-10-19T03:00:00.000Z',
      });

    expectApiSuccess(response, 200, 'D5 update event');
    expect(response.body.data.title).toBe('Belajar pemrograman (reschedule)');
    expect(response.body.data.startsAt).toBe('2026-10-19T01:00:00.000Z');
  });

  it('D6 — payload kegiatan tidak valid ditolak dengan 400', async () => {
    const emptyTitle = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: '',
        startsAt: '2026-10-20T01:00:00.000Z',
        endsAt: '2026-10-20T02:00:00.000Z',
      });
    expectApiError(emptyTitle, 400, 'VALIDATION_ERROR', 'D6 empty title');

    const unknownField = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Valid',
        startsAt: '2026-10-20T01:00:00.000Z',
        endsAt: '2026-10-20T02:00:00.000Z',
        colour: 'red',
      });
    expectApiError(unknownField, 400, 'VALIDATION_ERROR', 'D6 unknown field');

    const invalidTimestamp = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Valid',
        startsAt: 'besok pagi',
        endsAt: '2026-10-20T02:00:00.000Z',
      });
    expectApiError(invalidTimestamp, 400, 'VALIDATION_ERROR', 'D6 invalid timestamp');
  });

  it('D7 — Zero IDOR: user B tidak dapat membaca, mengubah, atau menghapus event user A', async () => {
    const read = await request(app.server)
      .get(`/api/v1/calendar/events/${eventId}`)
      .set('Authorization', bearer(userB.accessToken));
    expectApiError(read, 404, 'RESOURCE_NOT_FOUND', 'D7 cross-tenant read');

    const update = await request(app.server)
      .patch(`/api/v1/calendar/events/${eventId}`)
      .set('Authorization', bearer(userB.accessToken))
      .send({ title: 'Dibajak' });
    expectApiError(update, 404, 'RESOURCE_NOT_FOUND', 'D7 cross-tenant update');

    const remove = await request(app.server)
      .delete(`/api/v1/calendar/events/${eventId}`)
      .set('Authorization', bearer(userB.accessToken));
    expectApiError(remove, 404, 'RESOURCE_NOT_FOUND', 'D7 cross-tenant delete');

    const list = await request(app.server)
      .get('/api/v1/calendar/events?from=2026-10-01&to=2026-10-31')
      .set('Authorization', bearer(userB.accessToken))
      .expect(200);
    expect(list.body.data.events).toHaveLength(0);
    expect(list.body.data.tasks).toHaveLength(0);
  });

  it('D8 — menghapus kegiatan mengembalikan 200 dan data tidak muncul lagi di agenda', async () => {
    const created = await request(app.server)
      .post('/api/v1/calendar/events')
      .set('Authorization', bearer(userA.accessToken))
      .send({
        title: 'Agenda sementara',
        startsAt: '2026-10-21T01:00:00.000Z',
        endsAt: '2026-10-21T02:00:00.000Z',
      })
      .expect(201);
    const createdId = created.body.data.id as string;

    const deleted = await request(app.server)
      .delete(`/api/v1/calendar/events/${createdId}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiSuccess(deleted, 200, 'D8 delete event');
    expect(deleted.body.data.deleted).toBe(true);

    const afterDelete = await request(app.server)
      .get(`/api/v1/calendar/events/${createdId}`)
      .set('Authorization', bearer(userA.accessToken));
    expectApiError(afterDelete, 404, 'RESOURCE_NOT_FOUND', 'D8 get after delete');
  });
});
