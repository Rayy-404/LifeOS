import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { DateRangeHelper } from '../src/common/utils/date-range.helper';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * Habits E2E (`03-technical-spec.md` Section 4.3 & `04-architecture-security-testing.md` Section 14).
 */
describe('Habits (e2e) — /api/v1/habits', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const runId = Date.now();
  const password = 'sup3r-secret-password';
  const emailA = `habits-e2e-a-${runId}@example.com`;
  const emailB = `habits-e2e-b-${runId}@example.com`;

  let tokenA = '';
  let tokenB = '';
  let habitIdA = '';
  const todayLocal = DateRangeHelper.getTodayLocalDateString('Asia/Jakarta');

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
        name: 'Habit User A',
        email: emailA,
        password,
        timezone: 'Asia/Jakarta',
      })
      .expect(201);
    tokenA = regA.body.data.accessToken as string;

    const regB = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        name: 'Habit User B',
        email: emailB,
        password,
        timezone: 'Asia/Jakarta',
      })
      .expect(201);
    tokenB = regB.body.data.accessToken as string;
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { email: { startsWith: 'habits-e2e-' } },
    });
    await app.close();
  });

  it('POST /habits — menolak activeDays tidak valid ([], [0], [8], [1, 1, 3]) dengan 400 VALIDATION_ERROR', async () => {
    const invalidPayloads = [[], [0], [8], [1, 1, 3]];

    for (const activeDays of invalidPayloads) {
      const res = await request(app.getHttpServer())
        .post('/api/v1/habits')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          name: 'Habit Invalid',
          activeDays,
        })
        .expect(400);

      expect(res.body.code).toBe('VALIDATION_ERROR');
    }
  });

  it('POST /habits — membuat kebiasaan baru dan menyimpan activeDays secara kanonik terurut', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/habits')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        name: 'Membaca Buku',
        description: 'Membaca selama 20 menit',
        activeDays: [7, 1, 2, 3, 4, 5, 6],
      })
      .expect(201);

    expect(res.body.data.name).toBe('Membaca Buku');
    expect(res.body.data.activeDays).toEqual([1, 2, 3, 4, 5, 6, 7]);
    expect(res.body.data.currentStreak).toBe(0);
    expect(res.body.data.completedToday).toBe(false);
    expect(res.body.data.weeklyLogs).toHaveLength(7);
    habitIdA = res.body.data.id as string;
  });

  it('PUT /habits/:id/logs/:date — idempotent check-in 3x berturut-turut hanya menghasilkan 1 baris di habit_logs', async () => {
    let firstCompletedAt = '';

    for (let i = 0; i < 3; i++) {
      const res = await request(app.getHttpServer())
        .put(`/api/v1/habits/${habitIdA}/logs/${todayLocal}`)
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ completed: true })
        .expect(200);

      expect(res.body.data.habitId).toBe(habitIdA);
      expect(res.body.data.logDate).toBe(todayLocal);
      expect(res.body.data.completed).toBe(true);
      expect(res.body.data.currentStreak).toBe(1);
      if (i === 0) {
        firstCompletedAt = res.body.data.completedAt as string;
      } else {
        expect(res.body.data.completedAt).toBe(firstCompletedAt);
      }
    }

    const dbCount = await prisma.habitLog.count({
      where: { habitId: habitIdA },
    });
    expect(dbCount).toBe(1);
  });

  it('PUT /habits/:id/logs/:date — menolak tanggal masa depan (400 FUTURE_HABIT_LOG_NOT_ALLOWED) dan backfill > H-7', async () => {
    const tomorrow = DateRangeHelper.addDaysToDateString(todayLocal, 1);
    const futureRes = await request(app.getHttpServer())
      .put(`/api/v1/habits/${habitIdA}/logs/${tomorrow}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ completed: true })
      .expect(400);

    expect(futureRes.body.code).toBe('FUTURE_HABIT_LOG_NOT_ALLOWED');

    const eightDaysAgo = DateRangeHelper.addDaysToDateString(todayLocal, -8);
    await request(app.getHttpServer())
      .put(`/api/v1/habits/${habitIdA}/logs/${eightDaysAgo}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ completed: true })
      .expect(400);
  });

  it('GET /habits/:id/logs — mengembalikan riwayat log terurut logDate DESC dan mengubah activeDays tidak menghapus histori', async () => {
    const yesterday = DateRangeHelper.addDaysToDateString(todayLocal, -1);
    await request(app.getHttpServer())
      .put(`/api/v1/habits/${habitIdA}/logs/${yesterday}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ completed: true })
      .expect(200);

    // Edit activeDays -> histori tetap utuh
    await request(app.getHttpServer())
      .patch(`/api/v1/habits/${habitIdA}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ activeDays: [1, 2, 3, 4, 5, 6, 7] })
      .expect(200);

    const logsRes = await request(app.getHttpServer())
      .get(`/api/v1/habits/${habitIdA}/logs?from=${yesterday}&to=${todayLocal}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);

    expect(logsRes.body.data).toHaveLength(2);
    expect(logsRes.body.data[0].logDate).toBe(todayLocal);
    expect(logsRes.body.data[1].logDate).toBe(yesterday);
  });

  it('PUT /habits/:id/logs/:date { completed: false } — menghapus log secara bersih tanpa baris yatim', async () => {
    const yesterday = DateRangeHelper.addDaysToDateString(todayLocal, -1);
    const uncheckRes = await request(app.getHttpServer())
      .put(`/api/v1/habits/${habitIdA}/logs/${yesterday}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ completed: false })
      .expect(200);

    expect(uncheckRes.body.data.completed).toBe(false);
    expect(uncheckRes.body.data.completedAt).toBeNull();
    expect(uncheckRes.body.data.currentStreak).toBe(1);

    const remainingLogs = await prisma.habitLog.count({
      where: { habitId: habitIdA },
    });
    expect(remainingLogs).toBe(1);
  });

  it('Zero IDOR — User B tidak bisa membaca, mengubah, check-in, atau menghapus habit milik User A (404)', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/habits/${habitIdA}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);

    await request(app.getHttpServer())
      .patch(`/api/v1/habits/${habitIdA}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ name: 'Hacked Habit' })
      .expect(404);

    await request(app.getHttpServer())
      .put(`/api/v1/habits/${habitIdA}/logs/${todayLocal}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ completed: true })
      .expect(404);

    await request(app.getHttpServer())
      .get(`/api/v1/habits/${habitIdA}/logs`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/api/v1/habits/${habitIdA}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);
  });

  it('DELETE /habits/:id — menghapus habit beserta seluruh log terkait', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/habits/${habitIdA}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);

    const countAfter = await prisma.habitLog.count({
      where: { habitId: habitIdA },
    });
    expect(countAfter).toBe(0);
  });
});
