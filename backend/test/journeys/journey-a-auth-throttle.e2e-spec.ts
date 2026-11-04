import * as request from 'supertest';
import { createJourneyApp } from '../support/journey-app';
import { expectApiError } from '../support/journey-assertions';

/**
 * Journey A (bagian keamanan) — rate limiting pada endpoint auth
 * (`04-architecture-security-testing.md` §14.1 & §14.2).
 * Suite ini SENGAJA memakai `ThrottlerGuard` sungguhan (tidak di-disable).
 */
describe('Journey A — Auth Rate Limiting (e2e)', () => {
  let app: Awaited<ReturnType<typeof createJourneyApp>>;

  beforeAll(async () => {
    app = await createJourneyApp();
  });

  afterAll(async () => {
    await app.app.close();
  });

  it('A10 — login brute force dibatasi dengan 429 RATE_LIMIT_EXCEEDED', async () => {
    const credentials = {
      email: 'brute-force-target@example.com',
      password: 'sup3r-secret-password',
    };

    let rateLimited = false;
    let limitedResponse: request.Response | null = null;

    for (let attempt = 0; attempt < 15; attempt += 1) {
      const response = await request(app.server)
        .post('/api/v1/auth/login')
        .send(credentials);

      if (response.status === 429) {
        rateLimited = true;
        limitedResponse = response;
        break;
      }
    }

    expect(rateLimited).toBe(true);
    expectApiError(
      limitedResponse as unknown as request.Response,
      429,
      'RATE_LIMIT_EXCEEDED',
      'A10 rate limit',
    );
  });
});
