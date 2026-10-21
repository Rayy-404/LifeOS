#!/usr/bin/env node
/**
 * Release Gate P95 check (`planning/06` Fase 7 langkah 4).
 *
 * Mengukur latensi lokal untuk `GET /dashboard/today` dan `GET /tasks`
 * dan gagal (exit 1) bila P95 melewati 200 ms.
 *
 * Pakai: node ./scripts/latency-check.js [baseUrl] [jumlahRequest]
 */
const { PrismaClient } = require('@prisma/client');

const BASE_URL = process.argv[2] || 'http://localhost:3000/api/v1';
const SAMPLES = Number(process.argv[3] || 100);
const WARMUP = 10;
const P95_LIMIT_MS = 200;

const prisma = new PrismaClient();

async function api(path, options = {}) {
  const response = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(
      `${options.method || 'GET'} ${path} -> ${response.status} ${JSON.stringify(body)}`,
    );
  }
  return body;
}

function percentile(sorted, p) {
  if (sorted.length === 0) return 0;
  const index = Math.min(
    sorted.length - 1,
    Math.ceil((p / 100) * sorted.length) - 1,
  );
  return sorted[index];
}

async function measure(path, token) {
  const headers = { Authorization: `Bearer ${token}` };
  for (let i = 0; i < WARMUP; i += 1) {
    await api(path, { headers });
  }

  const samples = [];
  for (let i = 0; i < SAMPLES; i += 1) {
    const started = process.hrtime.bigint();
    await api(path, { headers });
    const elapsedMs = Number(process.hrtime.bigint() - started) / 1e6;
    samples.push(elapsedMs);
  }

  const sorted = [...samples].sort((a, b) => a - b);
  return {
    path,
    samples: samples.length,
    p50: percentile(sorted, 50),
    p95: percentile(sorted, 95),
    max: sorted[sorted.length - 1],
  };
}

async function main() {
  const runId = Date.now();
  const email = `latency-check-${runId}@example.com`;
  const password = 'sup3r-secret-password';

  const session = await api('/auth/register', {
    method: 'POST',
    body: JSON.stringify({ name: 'Latency Check', email, password }),
  });
  const token = session.data.accessToken;
  const userId = session.data.user.id;

  try {
    const now = Date.now();
    for (let i = 0; i < 20; i += 1) {
      await api('/tasks', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: JSON.stringify({
          title: `Latency task ${i}`,
          dueAt: new Date(now + i * 3600_000).toISOString(),
        }),
      });
    }
    for (let i = 0; i < 5; i += 1) {
      await api('/habits', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: JSON.stringify({ name: `Latency habit ${i}`, activeDays: [1, 2, 3, 4, 5, 6, 7] }),
      });
    }
    for (let i = 0; i < 10; i += 1) {
      const start = new Date(now + i * 3600_000);
      await api('/calendar/events', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: JSON.stringify({
          title: `Latency event ${i}`,
          startsAt: start.toISOString(),
          endsAt: new Date(start.getTime() + 3600_000).toISOString(),
        }),
      });
    }

    const results = [];
    results.push(await measure('/dashboard/today', token));
    results.push(await measure('/tasks', token));

    console.log(`\nBase URL: ${BASE_URL} (${SAMPLES} samples per endpoint)\n`);
    console.log('| Endpoint            | P50 (ms) | P95 (ms) | Max (ms) |');
    console.log('| :------------------ | -------: | -------: | -------: |');
    for (const result of results) {
      console.log(
        `| ${result.path.padEnd(20)} | ${result.p50.toFixed(2).padStart(7)} | ` +
          `${result.p95.toFixed(2).padStart(7)} | ${result.max.toFixed(2).padStart(7)} |`,
      );
    }

    const failed = results.filter((result) => result.p95 >= P95_LIMIT_MS);
    console.log(
      `\nAmbang gate: P95 < ${P95_LIMIT_MS} ms. ` +
        (failed.length === 0
          ? 'STATUS: LULUS'
          : `STATUS: GAGAL (${failed.map((r) => r.path).join(', ')})`),
    );
    process.exitCode = failed.length === 0 ? 0 : 1;
  } finally {
    await prisma.user.deleteMany({ where: { id: userId } });
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error('Latency check failed:', error.message);
  process.exit(1);
});
