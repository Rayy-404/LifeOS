import * as request from 'supertest';

/**
 * Assertion helper that prints the actual payload when an API error contract
 * does not match (Playbook 3: "laporan error yang jelas").
 */
export function expectApiError(
  response: request.Response,
  expectedStatus: number,
  expectedCode: string,
  context: string,
): void {
  const actualCode = (response.body as { code?: string } | undefined)?.code;
  if (response.status !== expectedStatus || actualCode !== expectedCode) {
    throw new Error(
      `[${context}] expected ${expectedStatus}/${expectedCode} but received ` +
        `${response.status}/${actualCode ?? 'no-code'} :: ` +
        JSON.stringify(response.body),
    );
  }
}

/**
 * Asserts a success status and prints the payload on mismatch.
 */
export function expectApiSuccess(
  response: request.Response,
  expectedStatus: number,
  context: string,
): void {
  if (response.status !== expectedStatus) {
    throw new Error(
      `[${context}] expected ${expectedStatus} but received ${response.status} :: ` +
        JSON.stringify(response.body),
    );
  }
}
