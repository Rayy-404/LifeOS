import * as request from 'supertest';
import { createJourneyApp } from '../support/journey-app';
import {
  expectApiError,
  expectApiSuccess,
} from '../support/journey-assertions';
import {
  bearer,
  cleanupJourneyUsers,
  JOURNEY_PASSWORD,
  registerJourneyUser,
  uniqueJourneyEmail,
} from '../support/journey-fixtures';

/**
 * Journey A — Register → Login → Refresh Token Rotation → Logout & Revoke
 * (`03-technical-spec.md` §4.1, `04-architecture-security-testing.md` §14.2).
 */
describe('Journey A — Auth & Session Lifecycle (e2e)', () => {
  let app: Awaited<ReturnType<typeof createJourneyApp>>;

  const email = uniqueJourneyEmail('journey-a');
  const emailB = uniqueJourneyEmail('journey-a-b');
  const password = JOURNEY_PASSWORD;

  beforeAll(async () => {
    app = await createJourneyApp({ disableThrottle: true });
  });

  afterAll(async () => {
    await cleanupJourneyUsers(app.prisma, 'journey-a');
    await app.app.close();
  });

  it('A1 — register publishes access + refresh tokens without leaking the password hash', async () => {
    const response = await request(app.server)
      .post('/api/v1/auth/register')
      .send({ name: 'Journey A', email, password, timezone: 'Asia/Jakarta' });

    expectApiSuccess(response, 201, 'A1 register');
    expect(response.body.data.user.email).toBe(email);
    expect(response.body.data.user).not.toHaveProperty('passwordHash');
    expect(response.body.data.accessToken).toEqual(expect.any(String));
    expect(response.body.data.refreshToken).toEqual(expect.any(String));
    expect(response.body.data.expiresIn).toBe(900);
  });

  it('A2 — register with the same email in a different letter case is rejected with 409', async () => {
    const response = await request(app.server)
      .post('/api/v1/auth/register')
      .send({ name: 'Journey A Duplicate', email: email.toUpperCase(), password });

    expectApiError(response, 409, 'CONFLICT_ERROR', 'A2 duplicate email');
  });

  it('A3 — login succeeds regardless of email letter case', async () => {
    const response = await request(app.server)
      .post('/api/v1/auth/login')
      .send({ email: email.toUpperCase(), password });

    expectApiSuccess(response, 200, 'A3 login');
    expect(response.body.data.user.email).toBe(email);
  });

  it('A4 — login with a wrong password is rejected with 401', async () => {
    const response = await request(app.server)
      .post('/api/v1/auth/login')
      .send({ email, password: 'wrong-password-123' });

    expectApiError(response, 401, 'UNAUTHORIZED', 'A4 wrong password');
  });

  it('A5 — GET /auth/me returns the profile for a valid bearer token', async () => {
    const user = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-a-me') });
    const response = await request(app.server)
      .get('/api/v1/auth/me')
      .set('Authorization', bearer(user.accessToken));

    expectApiSuccess(response, 200, 'A5 profile');
    expect(response.body.data.email).toBe(user.email);
    expect(response.body.data).not.toHaveProperty('passwordHash');
  });

  it('A6 — protected routes reject missing and malformed tokens with 401', async () => {
    const missing = await request(app.server).get('/api/v1/auth/me');
    expectApiError(missing, 401, 'UNAUTHORIZED', 'A6 missing token');

    const malformed = await request(app.server)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer not-a-real-token');
    expectApiError(malformed, 401, 'UNAUTHORIZED', 'A6 malformed token');
  });

  it('A7 — refresh rotates the token pair', async () => {
    const user = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-a-refresh') });
    const response = await request(app.server)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken });

    expectApiSuccess(response, 200, 'A7 refresh');
    expect(response.body.data.refreshToken).not.toBe(user.refreshToken);

    // Catatan: access token JWT memakai `iat` per detik, sehingga token yang
    // di-refresh pada detik yang sama byte-for-byte sama. Yang wajib berubah
    // adalah refresh token; access token baru tetap valid.
    const profile = await request(app.server)
      .get('/api/v1/auth/me')
      .set('Authorization', bearer(response.body.data.accessToken));
    expectApiSuccess(profile, 200, 'A7 access token valid after refresh');
    expect(profile.body.data.email).toBe(user.email);
  });

  it('A8 — reusing a rotated refresh token is detected and revokes the whole session family', async () => {
    const user = await registerJourneyUser(app.server, { email: uniqueJourneyEmail('journey-a-reuse') });

    const rotated = await request(app.server)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(200);
    const rotatedRefreshToken = rotated.body.data.refreshToken as string;

    const reuse = await request(app.server)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken });
    expectApiError(reuse, 401, 'TOKEN_REUSE_DETECTED', 'A8 refresh reuse');

    const afterRevoke = await request(app.server)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: rotatedRefreshToken });
    expectApiError(
      afterRevoke,
      401,
      'TOKEN_REUSE_DETECTED',
      'A8 rotated token revoked',
    );

    const activeTokens = await app.prisma.refreshToken.count({
      where: { userId: user.id, revokedAt: null },
    });
    expect(activeTokens).toBe(0);
  });

  it('A9 — logout revokes the refresh token idempotently and blocks further refresh', async () => {
    const user = await registerJourneyUser(app.server, { email: emailB });

    const logout = await request(app.server)
      .post('/api/v1/auth/logout')
      .set('Authorization', bearer(user.accessToken))
      .send({ refreshToken: user.refreshToken });
    expectApiSuccess(logout, 200, 'A9 logout');
    expect(logout.body.data.revoked).toBe(true);

    const secondLogout = await request(app.server)
      .post('/api/v1/auth/logout')
      .set('Authorization', bearer(user.accessToken))
      .send({ refreshToken: user.refreshToken });
    expectApiSuccess(secondLogout, 200, 'A9 logout idempotent');

    const refresh = await request(app.server)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken });
    // Token yang sudah dicabut (via logout) diperlakukan sebagai reuse oleh
    // mekanisme deteksi reuse, sehingga seluruh sesi ikut dicabut.
    expectApiError(
      refresh,
      401,
      'TOKEN_REUSE_DETECTED',
      'A9 refresh after logout',
    );
  });

  it('A10 — logout tanpa access token ditolak 401', async () => {
    const user = await registerJourneyUser(app.server, {
      email: uniqueJourneyEmail('journey-a-logout-guard'),
    });

    const response = await request(app.server)
      .post('/api/v1/auth/logout')
      .send({ refreshToken: user.refreshToken });
    expectApiError(response, 401, 'UNAUTHORIZED', 'A10 logout without token');
  });
});
