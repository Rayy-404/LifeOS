import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * Tasks E2E (`03-technical-spec.md` Section 4.2 & `04-architecture-security-testing.md` Section 14).
 */
describe('Tasks (e2e) — /api/v1/tasks', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const runId = Date.now();
  const password = 'sup3r-secret-password';
  const emailA = `tasks-e2e-a-${runId}@example.com`;
  const emailB = `tasks-e2e-b-${runId}@example.com`;

  let tokenA = '';
  let tokenB = '';
  let taskIdA = '';

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
      .send({ name: 'User A', email: emailA, password, timezone: 'Asia/Jakarta' })
      .expect(201);
    tokenA = regA.body.data.accessToken as string;

    const regB = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ name: 'User B', email: emailB, password, timezone: 'Asia/Jakarta' })
      .expect(201);
    tokenB = regB.body.data.accessToken as string;
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { email: { startsWith: 'tasks-e2e-' } },
    });
    await app.close();
  });

  it('POST /tasks — membuat tugas baru', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        title: 'Menyelesaikan proyek Flutter',
        description: 'Implementasi task manager',
        priority: 'HIGH',
        dueAt: '2026-10-20T12:00:00.000Z',
      })
      .expect(201);

    expect(res.body.data.title).toBe('Menyelesaikan proyek Flutter');
    expect(res.body.data.status).toBe('TODO');
    expect(res.body.data.priority).toBe('HIGH');
    expect(res.body.data.completedAt).toBeNull();
    taskIdA = res.body.data.id as string;
  });

  it('GET /tasks — menampilkan daftar tugas dengan filter & search', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/v1/tasks?status=TODO&priority=HIGH&search=flutter')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);

    expect(res.body.data).toHaveLength(1);
    expect(res.body.meta.totalItems).toBe(1);
  });

  it('PATCH /tasks/:id — mengubah status ke DONE mengisi completedAt, dan membuka kembali mengosongkan completedAt', async () => {
    const doneRes = await request(app.getHttpServer())
      .patch(`/api/v1/tasks/${taskIdA}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ status: 'DONE' })
      .expect(200);

    expect(doneRes.body.data.status).toBe('DONE');
    expect(doneRes.body.data.completedAt).toEqual(expect.any(String));

    const reopenRes = await request(app.getHttpServer())
      .patch(`/api/v1/tasks/${taskIdA}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ status: 'TODO' })
      .expect(200);

    expect(reopenRes.body.data.status).toBe('TODO');
    expect(reopenRes.body.data.completedAt).toBeNull();
  });

  it('Zero IDOR — User B tidak bisa membaca, mengubah, atau menghapus tugas milik User A (404)', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/tasks/${taskIdA}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);

    await request(app.getHttpServer())
      .patch(`/api/v1/tasks/${taskIdA}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ title: 'Diambil alih' })
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/api/v1/tasks/${taskIdA}`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);
  });

  it('DELETE /tasks/:id — menghapus tugas milik sendiri', async () => {
    const delRes = await request(app.getHttpServer())
      .delete(`/api/v1/tasks/${taskIdA}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);

    expect(delRes.body.data).toEqual({ id: taskIdA, deleted: true });

    await request(app.getHttpServer())
      .get(`/api/v1/tasks/${taskIdA}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(404);
  });
});
