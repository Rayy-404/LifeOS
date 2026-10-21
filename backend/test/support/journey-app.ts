import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import { AllExceptionsFilter } from '../../src/common/filters/all-exceptions.filter';
import { PrismaService } from '../../src/prisma/prisma.service';

export interface JourneyApp {
  app: INestApplication;
  prisma: PrismaService;
  server: ReturnType<INestApplication['getHttpServer']>;
}

/**
 * Boots the real NestJS application (same global pipe/filter as `main.ts`)
 * for journey-level E2E suites.
 *
 * @param options.disableThrottle disables the global `ThrottlerGuard` so a
 *        journey can issue more than 60 requests per minute. The dedicated
 *        throttle suite keeps the guard enabled to prove rate limiting.
 */
export async function createJourneyApp(
  options: { disableThrottle?: boolean } = {},
): Promise<JourneyApp> {
  const builder = Test.createTestingModule({ imports: [AppModule] });

  if (options.disableThrottle) {
    builder.overrideProvider(ThrottlerGuard).useValue({
      canActivate: () => true,
    });
  }

  const moduleRef = await builder.compile();
  const app = moduleRef.createNestApplication();

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());
  await app.init();

  return {
    app,
    prisma: app.get(PrismaService),
    server: app.getHttpServer(),
  };
}
