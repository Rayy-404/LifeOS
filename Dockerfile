# syntax=docker/dockerfile:1.7

# ---------- Build stage ----------
FROM node:24-bookworm-slim AS build

WORKDIR /app
ENV NODE_ENV=development

# Prisma needs OpenSSL at generate/build time. Max-FutureTime tolerates small
# clock skew on build hosts without disabling apt signature verification.
RUN apt-get -o Acquire::Max-FutureTime=3600 update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY backend/package.json backend/package-lock.json ./
RUN npm ci

COPY backend/prisma ./prisma
RUN npx prisma generate

COPY backend/nest-cli.json backend/tsconfig.json backend/tsconfig.build.json ./
COPY backend/src ./src
RUN npm run build

# Keep only production dependencies
RUN npm prune --omit=dev

# ---------- Runtime stage ----------
FROM node:24-bookworm-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=7860
ENV CORS_ORIGIN="*"
ENV JWT_ACCESS_TTL="15m"
ENV REFRESH_TOKEN_TTL_DAYS="7"
ENV THROTTLE_LIMIT="100"
ENV SWAGGER_ENABLED="true"

RUN apt-get -o Acquire::Max-FutureTime=3600 update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build --chown=node:node /app/package.json /app/package-lock.json ./
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --from=build --chown=node:node /app/prisma ./prisma
COPY --chown=node:node backend/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

USER node

EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:7860/api/v1/health').then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

ENTRYPOINT ["./docker-entrypoint.sh"]
