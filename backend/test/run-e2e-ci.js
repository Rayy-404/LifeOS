#!/usr/bin/env node
/**
 * CI runner untuk E2E suite (`05-engineering-playbooks.md` Playbook 3).
 *
 * Menjalankan suite Jest E2E maksimal dua kali. Retry dilakukan di level suite
 * (bukan per test) sehingga setiap percobaan memulai state aplikasi dan
 * database yang bersih — data test memakai e-mail unik per run dan dibersihkan
 * lewat `cleanupJourneyUsers`.
 */
const { spawnSync } = require('node:child_process');

const MAX_ATTEMPTS = Number(process.env.E2E_MAX_ATTEMPTS || 2);
const jestArgs = [
  '--config',
  './test/jest-e2e.json',
  '--runInBand',
  '--ci',
  '--detectOpenHandles',
];

for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
  console.log(`\n[e2e:ci] percobaan ${attempt}/${MAX_ATTEMPTS}`);

  const result = spawnSync('npx', ['jest', ...jestArgs], {
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });

  if (result.status === 0) {
    console.log('[e2e:ci] suite hijau');
    process.exit(0);
  }

  console.warn(
    `[e2e:ci] percobaan ${attempt} gagal (exit code ${result.status})`,
  );
}

console.error('[e2e:ci] suite tetap gagal setelah semua percobaan');
process.exit(1);
