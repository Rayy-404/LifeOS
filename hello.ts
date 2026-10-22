import { parseEnv } from "@neon/env";
import { attachDatabasePool } from "@neon/functions";
import { Pool } from "pg";
import config from "./neon";

const env = parseEnv(config, [
  "DATABASE_URL",
  "NEON_AUTH_BASE_URL",
  "NEON_AUTH_JWKS_URL",
]);

const pool = new Pool({
  connectionString: env.postgres.databaseUrl,
  max: 5,
});
attachDatabasePool(pool);

export default {
  async fetch(_request: Request): Promise<Response> {
    const dbResult = await pool.query<{
      database: string;
      public_tables: number;
      neon_auth_tables: number;
    }>(`
      SELECT
        current_database() AS database,
        (SELECT count(*)::int FROM information_schema.tables WHERE table_schema = 'public') AS public_tables,
        (SELECT count(*)::int FROM information_schema.tables WHERE table_schema = 'neon_auth') AS neon_auth_tables
    `);

    const jwksRes = await fetch(env.auth.jwksUrl);
    const jwks = (await jwksRes.json()) as { keys?: unknown[] };

    return Response.json({
      status: "ok",
      service: "lifeos-neon-function",
      branch: process.env.NEON_BRANCH ?? "production",
      postgres: dbResult.rows[0],
      neonAuth: {
        baseUrl: env.auth.baseUrl,
        jwksUrl: env.auth.jwksUrl,
        jwksKeysCount: Array.isArray(jwks.keys) ? jwks.keys.length : 0,
      },
      timestamp: new Date().toISOString(),
    });
  },
};
