import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { DateRangeHelper } from '../src/common/utils/date-range.helper';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * Reminder & Statistics E2E (`03-technical-spec.md` §3.2, §4.5, §4.6 &
 * `04-architecture-security-testing.md` §14.2).
 */
describe('Reminders & Statistics (e2e) — /api/v1/reminders & /api/v1/statistics', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const runId = Date.now();
  const password = 'sup3r-secret-password';
  const emailA = `remstat-e2e-a-${runId}@example.com`;
  const emailB = `remstat-e2e-b-${runId}@example.com`;

  let tokenA = '';
  let tokenB = '';
  let taskAId = '';
  let eventAId = '';
  let taskBId = '';
  let reminderId = '';

  const futureIso = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const laterIso = new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString();

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
      .send({ name: 'RemStat A', email: emailA, password, timezone: 'Asia/Jakarta' })
      .expect(201);
    tokenA = regA.body.data.accessToken as string;

    const regB = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ name: 'RemStat B', email: emailB, password, timezone: 'Asia/Jakarta' })
      .expect(201);
    tokenB = regB.body.data.accessToken as string;

    const taskA = await request(app.getHttpServer())
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Reminder Target Task A',
        dueAt: futureIso,
      })
      .expect(201);
    taskAId = taskA.body.data.id as string;

    const taskB = await request(app.getHttpServer())
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ title: 'Reminder Target Task B', dueAt: futureIso })
      .expect(201);
    taskBId = taskB.body.data.id as string;

    const eventA = await request(app.getHttpServer())
      .post('/api/v1/calendar/events')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Reminder Target Event A',
        startsAt: futureIso,
        endsAt: new Date(Date.now() + 26 * 60 * 60 * 1000).toISOString(),
      })
      .expect(201);
    eventAId = eventA.body.data.id as string;
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { email: { startsWith: 'remstat-e2e-' } },
    });
    await app.close();
  });

  describe('Reminder XOR & ownership', () => {
    it('menolak reminder tanpa target atau dua target (400 REMINDER_TARGET_XOR_VIOLATION)', async () => {
      const none = await request(app.getHttpServer())
        .post('/api/v1/reminders')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ remindAt: futureIso })
        .expect(400);
      expect(none.body.code).toBe('REMINDER_TARGET_XOR_VIOLATION');

      const both = await request(app.getHttpServer())
        .post('/api/v1/reminders')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ taskId: taskAId, eventId: eventAId, remindAt: futureIso })
        .expect(400);
      expect(both.body.code).toBe('REMINDER_TARGET_XOR_VIOLATION');
    });

    it('menolak taskId milik user lain dengan 404 (Zero IDOR)', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/reminders')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ taskId: taskBId, remindAt: futureIso })
        .expect(404);
      expect(res.body.code).toBe('RESOURCE_NOT_FOUND');
    });

    it('menolak remindAt di masa lalu dengan 400 INVALID_REMINDER_TIME', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/reminders')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          taskId: taskAId,
          remindAt: new Date(Date.now() - 60_000).toISOString(),
        })
        .expect(400);
      expect(res.body.code).toBe('INVALID_REMINDER_TIME');
    });

    it('membuat reminder milik sendiri sebagai SCHEDULED', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/reminders')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ taskId: taskAId, remindAt: futureIso })
        .expect(201);

      reminderId = res.body.data.id as string;
      expect(res.body.data.status).toBe('SCHEDULED');
      expect(res.body.data.task.id).toBe(taskAId);
    });

    it('user B tidak dapat mengubah reminder user A (404)', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/api/v1/reminders/${reminderId}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ status: 'CANCELLED' })
        .expect(404);
      expect(res.body.code).toBe('RESOURCE_NOT_FOUND');
    });
  });

  describe('Reminder lifecycle matrix (§3.2)', () => {
    it('PATCH remindAt ke masa depan mengembalikan status SCHEDULED', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/api/v1/reminders/${reminderId}`)
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ remindAt: laterIso })
        .expect(200);
      expect(res.body.data.status).toBe('SCHEDULED');
      expect(new Date(res.body.data.remindAt).toISOString()).toBe(
        new Date(laterIso).toISOString(),
      );
    });

    it('Task DONE membatalkan seluruh reminder SCHEDULED milik task tersebut', async () => {
      await request(app.getHttpServer())
        .patch(`/api/v1/tasks/${taskAId}`)
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ status: 'DONE' })
        .expect(200);

      const scheduled = await request(app.getHttpServer())
        .get('/api/v1/reminders?status=SCHEDULED')
        .set('Authorization', `Bearer ${tokenA}`)
        .expect(200);
      expect(
        scheduled.body.data.some(
          (reminder: { id: string }) => reminder.id === reminderId,
        ),
      ).toBe(false);

      const all = await request(app.getHttpServer())
        .get('/api/v1/reminders')
        .set('Authorization', `Bearer ${tokenA}`)
        .expect(200);
      const target = all.body.data.find(
        (reminder: { id: string }) => reminder.id === reminderId,
      );
      expect(target.status).toBe('CANCELLED');
    });

    it('menghapus CalendarEvent menghapus reminder terkait lewat ON DELETE CASCADE', async () => {
      const created = await request(app.getHttpServer())
        .post('/api/v1/reminders')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ eventId: eventAId, remindAt: futureIso })
        .expect(201);

      await request(app.getHttpServer())
        .delete(`/api/v1/calendar/events/${eventAId}`)
        .set('Authorization', `Bearer ${tokenA}`)
        .expect(200);

      const remaining = await prisma.reminder.findUnique({
        where: { id: created.body.data.id as string },
      });
      expect(remaining).toBeNull();
    });
  });

  describe('Statistics overview & weekly', () => {
    let from = '';
    let to = '';
    let doneDueDate = '';
    let overdueDueDate = '';

    beforeAll(async () => {
      to = DateRangeHelper.getTodayLocalDateString('Asia/Jakarta');
      from = DateRangeHelper.addDaysToDateString(to, -6);
      doneDueDate = DateRangeHelper.addDaysToDateString(to, -1);
      overdueDueDate = DateRangeHelper.addDaysToDateString(to, -2);

      await request(app.getHttpServer())
        .post('/api/v1/tasks')
        .set('Authorization', `Bearer ${tokenB}`)
        .send({
          title: 'Stats Done Task',
          status: 'DONE',
          dueAt: `${doneDueDate}T03:00:00.000Z`,
        })
        .expect(201);

      await request(app.getHttpServer())
        .post('/api/v1/tasks')
        .set('Authorization', `Bearer ${tokenB}`)
        .send({
          title: 'Stats Overdue Task',
          dueAt: `${overdueDueDate}T03:00:00.000Z`,
        })
        .expect(201);

      const habit = await request(app.getHttpServer())
        .post('/api/v1/habits')
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ name: 'Stats Habit', activeDays: [1, 2, 3, 4, 5, 6, 7] })
        .expect(201);

      await request(app.getHttpServer())
        .put(`/api/v1/habits/${habit.body.data.id}/logs/${to}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ completed: true })
        .expect(200);
    });

    it('GET /statistics/overview menghitung tasks & habits dari database', async () => {
      const res = await request(app.getHttpServer())
        .get(`/api/v1/statistics/overview?from=${from}&to=${to}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .expect(200);

      expect(res.body.data).toMatchObject({
        from,
        to,
        tasks: {
          total: 2,
          completed: 1,
          overdue: 1,
          completionRate: 50.0,
        },
        habits: {
          totalScheduledInstances: 7,
          totalCompletedInstances: 1,
          consistencyRate: 14.3,
        },
      });
    });

    it('GET /statistics/weekly membagi completedAt ke tanggal lokal dan menghitung habit', async () => {
      const today = DateRangeHelper.getTodayLocalDateString('Asia/Jakarta');
      const isoWeekday = DateRangeHelper.getIsoWeekday(today);
      const weekStart = DateRangeHelper.addDaysToDateString(
        today,
        -(isoWeekday - 1),
      );

      await request(app.getHttpServer())
        .post('/api/v1/tasks')
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ title: 'Stats Weekly Done', status: 'DONE' })
        .expect(201);

      const habit = await request(app.getHttpServer())
        .post('/api/v1/habits')
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ name: 'Stats Weekly Habit', activeDays: [1, 2, 3, 4, 5, 6, 7] })
        .expect(201);

      await request(app.getHttpServer())
        .put(`/api/v1/habits/${habit.body.data.id}/logs/${today}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ completed: true })
        .expect(200);

      const res = await request(app.getHttpServer())
        .get(`/api/v1/statistics/weekly?weekStart=${weekStart}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .expect(200);

      expect(res.body.data.days).toHaveLength(7);
      const todayPoint = res.body.data.days.find(
        (day: { date: string }) => day.date === today,
      );
      expect(todayPoint.tasksCompleted).toBeGreaterThanOrEqual(1);
      expect(todayPoint.habitsScheduled).toBeGreaterThanOrEqual(2);
      expect(todayPoint.habitsCompleted).toBeGreaterThanOrEqual(2);
    });
  });
});
