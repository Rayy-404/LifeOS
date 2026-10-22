import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

/**
 * Resolves the allowed CORS origins.
 *
 * Security audit F1: previously any origin was reflected (`origin: true`) with
 * `credentials: true`, which allowed credentialed cross-origin calls from any
 * website. Now an explicit allowlist is required and production fails fast
 * when `CORS_ORIGIN` is missing.
 */
function resolveCorsOrigins(): string[] {
  const raw = process.env.CORS_ORIGIN?.trim();
  if (!raw) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error(
        'Missing required environment variable: CORS_ORIGIN must list every ' +
          'allowed origin (comma separated) in production.',
      );
    }
    return ['http://localhost:3000', 'http://localhost:8080'];
  }

  return raw
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
}

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);

  // Close Prisma connections cleanly when Docker/Kubernetes sends SIGTERM.
  app.enableShutdownHooks();

  app.setGlobalPrefix('api/v1');
  app.use(helmet());

  // Security audit F10: only trust X-Forwarded-* when explicitly deployed
  // behind a known reverse proxy, otherwise every client shares one IP bucket
  // for rate limiting.
  const trustProxy = process.env.TRUST_PROXY?.trim();
  if (trustProxy) {
    const express = app.getHttpAdapter().getInstance() as {
      set?: (key: string, value: unknown) => void;
    };
    express.set?.('trust proxy', trustProxy);
  }

  app.enableCors({
    origin: resolveCorsOrigins(),
    credentials: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useGlobalFilters(new AllExceptionsFilter());

  // Security audit F2: the OpenAPI surface is only exposed outside production
  // (or when explicitly enabled with SWAGGER_ENABLED=true).
  const swaggerEnabled = process.env.SWAGGER_ENABLED
    ? process.env.SWAGGER_ENABLED === 'true'
    : process.env.NODE_ENV !== 'production';

  if (swaggerEnabled) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('LifeOS API')
      .setDescription(
        'LifeOS Personal Productivity & Academic OS REST API (/api/v1)',
      )
      .setVersion('1.0.0')
      .addBearerAuth()
      .build();

    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
}

void bootstrap();
