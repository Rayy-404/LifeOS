# syntax=docker/dockerfile:1.7

# ---------- Build stage ----------
FROM node:20-bookworm-slim AS build

WORKDIR /app
ENV NODE_ENV=development

# Prisma needs OpenSSL at generate/build time. Max-FutureTime tolerates small
# clock skew on build hosts without disabling apt signature verification.
RUN apt-get -o Acquire::Max-FutureTime=3600 update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci

COPY prisma ./prisma
RUN npx prisma generate

COPY nest-cli.json tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build

# Keep only production dependencies. `prisma` is a runtime dependency so the
# entrypoint can apply migrations on deploy.
RUN npm prune --omit=dev

# ---------- Runtime stage ----------
FROM node:20-bookworm-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

RUN apt-get -o Acquire::Max-FutureTime=3600 update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build --chown=node:node /app/package.json /app/package-lock.json ./
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --from=build --chown=node:node /app/prisma ./prisma
COPY --chown=node:node docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:3000/api/v1/health').then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

ENTRYPOINT ["./docker-entrypoint.sh"]
