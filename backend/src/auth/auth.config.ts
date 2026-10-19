import { ConfigService } from '@nestjs/config';

/**
 * Valid Argon2id hash used for constant-time dummy verification when a login
 * attempt references an email that does not exist (mitigates timing-based user enumeration).
 */
export const DUMMY_ARGON2_HASH =
  '$argon2id$v=19$m=65536,t=3,p=4$c29tZXNhbHR2YWx1ZQ$RdescudvJCsgt3ub+b+dWRWJTmaaJObG';

/**
 * Normalizes an email address to trimmed lowercase (`03-technical-spec.md` Section 3 & `OD-06`).
 */
export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

/**
 * Retrieves `JWT_ACCESS_SECRET` from configuration and fails fast if missing in non-test environments.
 */
export function getJwtAccessSecret(configService: ConfigService): string {
  const secret = configService.get<string>('JWT_ACCESS_SECRET')?.trim();
  if (secret && secret.length > 0) {
    return secret;
  }

  if (process.env.NODE_ENV === 'test') {
    return 'lifeos-test-only-jwt-secret-key-do-not-use-in-prod';
  }

  throw new Error(
    'Missing required environment variable: JWT_ACCESS_SECRET must be set.',
  );
}
