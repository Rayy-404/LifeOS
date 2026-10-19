import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * Auth lifecycle E2E (`03-technical-spec.md` Section 4.1 &
 * `04-architecture-security-testing.md` Section 14.1).
 * Requires a migrated PostgreSQL database (docker compose up -d + prisma migrate deploy).
 */
describe('Auth (e2e) — /api/v1/auth', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const runId = Date.now();
  const password = 'sup3r-secret-password';
  const emailA = `auth-e2e-a-${runId}@example.com`;
  const emailB = `auth-e2e-b-${runId}@example.com`;

  let accessTokenA = '';
  let refreshTokenA = '';
  let rotatedRefreshTokenA = '';

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
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { email: { startsWith: 'auth-e2e-' } },
    });
    await app.close();
  });

  it('POST /auth/register — membuat akun dan menerbitkan token', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        name: 'Rayhan',
        email: emailA,
        password,
        timezone: 'Asia/Jakarta',
      })
      .expect(201);

    expect(response.body.data.user.email).toBe(emailA);
    expect(response.body.data.user).not.toHaveProperty('passwordHash');
    expect(response.body.data.accessToken).toEqual(expect.any(String));
    expect(response.body.data.refreshToken).toEqual(expect.any(String));
    expect(response.body.data.expiresIn).toBe(900);

    accessTokenA = response.body.data.accessToken as string;
    refreshTokenA = response.body.data.refreshToken as string;
  });

  it('POST /auth/register — menolak email duplikat beda kapitalisasi (409)', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ name: 'Rayhan 2', email: emailA.toUpperCase(), password })
      .expect(409);

    expect(response.body.code).toBe('CONFLICT_ERROR');
  });

  it('POST /auth/login — berhasil dengan variasi kapitalisasi email', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: emailA.toUpperCase(), password })
      .expect(200);

    accessTokenA = response.body.data.accessToken as string;
    refreshTokenA = response.body.data.refreshToken as string;
  });

  it('GET /auth/me — mengembalikan profil dengan bearer token', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessTokenA}`)
      .expect(200);

    expect(response.body.data.email).toBe(emailA);
    expect(response.body.data).not.toHaveProperty('passwordHash');
  });

  it('GET /auth/me — menolak tanpa token (401)', async () => {
    await request(app.getHttpServer()).get('/api/v1/auth/me').expect(401);
  });

  it('POST /auth/refresh — merotasi token', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: refreshTokenA })
      .expect(200);

    expect(response.body.data.refreshToken).not.toBe(refreshTokenA);
    rotatedRefreshTokenA = response.body.data.refreshToken as string;
  });

  it('POST /auth/refresh — reuse token lama → 401 TOKEN_REUSE_DETECTED', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: refreshTokenA })
      .expect(401);

    expect(response.body.code).toBe('TOKEN_REUSE_DETECTED');
  });

  it('POST /auth/refresh — token hasil rotasi ikut tercabut setelah reuse terdeteksi', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: rotatedRefreshTokenA })
      .expect(401);
  });

  it('POST /auth/logout — mencabut refresh token secara idempotent', async () => {
    const register = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({ name: 'Nadia', email: emailB, password })
      .expect(201);

    const logout = await request(app.getHttpServer())
      .post('/api/v1/auth/logout')
      .send({ refreshToken: register.body.data.refreshToken })
      .expect(200);

    expect(logout.body.data.revoked).toBe(true);

    await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: register.body.data.refreshToken })
      .expect(401);
  });
});
