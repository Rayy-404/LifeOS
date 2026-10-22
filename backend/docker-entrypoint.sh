#!/bin/sh
set -eu

# Wait for PostgreSQL and apply committed migrations before starting the API.
# `prisma migrate deploy` is idempotent; retrying only covers a slow database start.
attempt=1
until ./node_modules/.bin/prisma migrate deploy; do
    if [ "$attempt" -ge 10 ]; then
        echo "[entrypoint] prisma migrate deploy failed after $attempt attempts" >&2
        exit 1
    fi
    attempt=$((attempt + 1))
    echo "[entrypoint] database not ready, retrying in 3s ($attempt/10)..." >&2
    sleep 3
done

echo "[entrypoint] starting LifeOS API..."
exec node dist/main.js
