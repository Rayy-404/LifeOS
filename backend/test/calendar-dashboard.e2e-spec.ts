import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * Calendar & Dashboard E2E (`03-technical-spec.md` Sections 3.3, 4.4, 4.6 & `04-architecture-security-testing.md` §14.2).
 */
describe('Calendar & Dashboard (e2e) — /api/v1/calendar & /api/v1/dashboard', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const runId = Date.now();
  const password = 'sup3r-secret-password';
  const emailA = `caldash-e2e-a-${runId}@example.com`;
  const emailB = `caldash-e2e-b-${runId}@example.com`;

  let tokenA = '';
  let tokenB = '';
  let eventIdLate18 = '';
  let eventIdMidnight19 = '';

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    await app.init();

    prisma = app.get(PrismaService);

    const regA = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        name: 'CalDash User A',
        email: emailA,
        password,
        timezone: 'Asia/Jakarta',
      })
      .expect(201);
    tokenA = regA.body.data.accessToken as string;

    const regB = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        name: 'CalDash User B',
        email: emailB,
        password,
        timezone: 'Asia/Jakarta',
      })
      .expect(201);
    tokenB = regB.body.data.accessToken as string;
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { email: { startsWith: 'caldash-e2e-' } },
    });
    await app.close();
  });

  it('POST /calendar/events — menolak endsAt <= startsAt dengan 400 INVALID_TIME_RANGE', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/calendar/events')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Event Invalid',
        startsAt: '2026-10-18T03:00:00.000Z',
        endsAt: '2026-10-18T01:00:00.000Z',
      })
      .expect(400);

    expect(res.body.code).toBe('INVALID_TIME_RANGE');
  });

  it('Uji Batas Tengah Malam [startUtc, endUtc) — item pukul 23:59 WIB vs 00:00 WIB tampil tepat di tanggal lokalnya tanpa terhitung ganda', async () => {
    // 2026-10-18 23:50–23:59 WIB = 2026-10-18T16:50:00.000Z .. 2026-10-18T16:59:00.000Z
    const ev18Res = await request(app.getHttpServer())
      .post('/api/v1/calendar/events')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Belajar Larut Malam 18 Okt',
        location: 'Kamar',
        startsAt: '2026-10-18T16:50:00.000Z',
        endsAt: '2026-10-18T16:59:00.000Z',
      })
      .expect(201);
    eventIdLate18 = ev18Res.body.data.id as string;

    // 2026-10-19 00:00–01:00 WIB = 2026-10-18T17:00:00.000Z .. 2026-10-18T18:00:00.000Z
    const ev19Res = await request(app.getHttpServer())
      .post('/api/v1/calendar/events')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Riset Tengah Malam 19 Okt',
        location: 'Meja Kerja',
        startsAt: '2026-10-18T17:00:00.000Z',
        endsAt: '2026-10-18T18:00:00.000Z',
      })
      .expect(201);
    eventIdMidnight19 = ev19Res.body.data.id as string;

    // Task pada 2026-10-18 23:59 WIB (16:59Z)
    await request(app.getHttpServer())
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Tugas Batas 23:59 18 Okt',
        priority: 'HIGH',
        dueAt: '2026-10-18T16:59:00.000Z',
      })
      .expect(201);

    // Task pada 2026-10-19 00:00 WIB (17:00Z)
    await request(app.getHttpServer())
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Tugas Batas 00:00 19 Okt',
        priority: 'MEDIUM',
        dueAt: '2026-10-18T17:00:00.000Z',
      })
      .expect(201);

    // Query agenda 2026-10-18
    const agenda18 = await request(app.getHttpServer())
      .get('/api/v1/calendar/events?from=2026-10-18&to=2026-10-18')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);

    expect(agenda18.body.data.events).toHaveLength(1);
    expect(agenda18.body.data.events[0].id).toBe(eventIdLate18);
    expect(agenda18.body.data.events[0].type).toBe('EVENT');
    expect(agenda18.body.data.tasks).toHaveLength(1);
    expect(agenda18.body.data.tasks[0].title).toBe('Tugas Batas 23:59 18 Okt');
    expect(agenda18.body.data.tasks[0].type).toBe('TASK');

    // Query agenda 2026-10-19
    const agenda19 = await request(app.getHttpServer())
      .get('/api/v1/calendar/events?from=2026-10-19&to=2026-10-19')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);

    expect(agenda19.body.data.events).toHaveLength(1);
    expect(agenda19.body.data.events[0].id).toBe(eventIdMidnight19);
    expect(agenda19.body.data.tasks).toHaveLength(1);
    expect(agenda19.body.data.tasks[0].title).toBe('Tugas Batas 00:00 19 Okt');
  });

  it('GET /dashboard/today?date=2026-10-18 — angka ringkasan identik dengan isi database', async () => {
    // Tambahkan 1 task tanpa dueAt (backlog aktif) dan 1 habit terjadwal Minggu (7)
    await request(app.getHttpServer())
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Tugas Backlog Tanpa Tenggat',
        priority: 'LOW',
      })
      .expect(201);

    const habitRes = await request(app.getHttpServer())
      .post('/api/v1/habits')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        name: 'Olahraga Minggu',
        activeDays: [7],
      })
      .expect(201);
    const habitId = habitRes.body.data.id as string;

    await request(app.getHttpServer())
      .put(`/api/v1/habits/${habitId}/logs/2026-10-18`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ completed: true })
      .expect(200);

    const dashRes = await request(app.getHttpServer())
      .get('/api/v1/dashboard/today?date=2026-10-18')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);

    const data = dashRes.body.data;
    expect(data.date).toBe('2026-10-18');
    expect(data.timezone).toBe('Asia/Jakarta');
    // Pada 2026-10-18: 1 task due 18 Okt (TODO) + 1 backlog tanpa dueAt (TODO) = 2 pending, 0 completed, total 2
    expect(data.tasks).toEqual({
      total: 2,
      completed: 0,
      pending: 2,
      overdue: 0,
    });
    expect(data.habits).toEqual({
      scheduled: 1,
      completed: 1,
    });
    expect(data.upcomingEvents).toHaveLength(1);
    expect(data.todayHabits).toHaveLength(1);
    expect(data.todayTasks).toHaveLength(2);
  });

  it('Zero IDOR — User B tidak bisa mengakses atau memodifikasi CalendarEvent milik User A', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/calendar/events/${eventIdLate18}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);

    await request(app.getHttpServer())
      .patch(`/api/v1/calendar/events/${eventIdLate18}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ title: 'Hacked' })
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/api/v1/calendar/events/${eventIdLate18}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);

    const dashB = await request(app.getHttpServer())
      .get('/api/v1/dashboard/today?date=2026-10-18')
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(200);

    expect(dashB.body.data.tasks.total).toBe(0);
    expect(dashB.body.data.upcomingEvents).toHaveLength(0);
  });
});
