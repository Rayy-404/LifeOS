import * as request from 'supertest';
import { INestApplication } from '@nestjs/common';

export type JourneyServer = ReturnType<INestApplication['getHttpServer']>;

export const JOURNEY_PASSWORD = 'sup3r-secret-password';

/**
 * Creates a unique e-mail per run so parallel/retried suites never collide
 * and cleanup can target a single prefix.
 */
export function uniqueJourneyEmail(prefix: string): string {
  const stamp = Date.now().toString(36);
  const noise = Math.random().toString(36).slice(2, 8);
  return `${prefix}-${stamp}-${noise}@example.com`;
}

export interface JourneyUser {
  id: string;
  name: string;
  email: string;
  password: string;
  accessToken: string;
  refreshToken: string;
}

export interface RegisterJourneyUserOptions {
  name?: string;
  email?: string;
  password?: string;
  timezone?: string;
}

/**
 * Registers a user through the public API and returns the issued session
 * (Playbook 3: auth helper/fixture so suites never repeat the full signup).
 */
export async function registerJourneyUser(
  server: JourneyServer,
  options: RegisterJourneyUserOptions = {},
): Promise<JourneyUser> {
  const email = options.email ?? uniqueJourneyEmail('journey');
  const password = options.password ?? JOURNEY_PASSWORD;
  const name = options.name ?? 'Journey User';

  const response = await request(server)
    .post('/api/v1/auth/register')
    .send({ name, email, password, timezone: options.timezone ?? 'Asia/Jakarta' })
    .expect(201);

  return {
    id: response.body.data.user.id as string,
    name,
    email,
    password,
    accessToken: response.body.data.accessToken as string,
    refreshToken: response.body.data.refreshToken as string,
  };
}

export function bearer(token: string): string {
  return `Bearer ${token}`;
}

/**
 * Removes every account created by a journey suite. Cascades remove tasks,
 * habits, logs, events, reminders, and refresh tokens.
 */
export async function cleanupJourneyUsers(
  prisma: { user: { deleteMany: (args: unknown) => Promise<{ count: number }> } },
  emailPrefix: string,
): Promise<void> {
  await prisma.user.deleteMany({
    where: { email: { startsWith: emailPrefix } },
  });
}
