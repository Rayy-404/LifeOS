import { Controller, Get, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthModule } from './auth/auth.module';
import { CalendarModule } from './calendar/calendar.module';
import { Public } from './common/decorators/public.decorator';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { DashboardModule } from './dashboard/dashboard.module';
import { HabitsModule } from './habits/habits.module';
import { PrismaModule } from './prisma/prisma.module';
import { PrismaService } from './prisma/prisma.service';
import { RemindersModule } from './reminders/reminders.module';
import { StatisticsModule } from './statistics/statistics.module';
import { TasksModule } from './tasks/tasks.module';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  @Get()
  @Public()
  @ApiOperation({ summary: 'Check API health status' })
  check() {
    return {
      data: {
        status: 'ok',
        service: 'lifeos-backend',
        branch: this.config.get<string>('NEON_BRANCH') ?? 'local',
        timestamp: new Date().toISOString(),
      },
    };
  }

  @Get('neon')
  @Public()
  @ApiOperation({
    summary:
      'Verify Neon services (Lakebase Postgres, Neon Auth, Neon Functions)',
  })
  async checkNeon() {
    const dbRows = await this.prisma.$queryRaw<
      Array<{ database: string; user_count: bigint }>
    >`SELECT current_database() AS database, (SELECT count(*) FROM users) AS user_count`;

    const authBaseUrl = this.config.get<string>('NEON_AUTH_BASE_URL') ?? null;
    const authJwksUrl = this.config.get<string>('NEON_AUTH_JWKS_URL') ?? null;
    const functionHelloUrl =
      this.config.get<string>('NEON_FUNCTION_HELLO_BASE_URL') ?? null;

    let jwksKeysCount = 0;
    if (authJwksUrl) {
      const jwksRes = await fetch(authJwksUrl);
      const jwks = (await jwksRes.json()) as { keys?: unknown[] };
      jwksKeysCount = Array.isArray(jwks.keys) ? jwks.keys.length : 0;
    }

    let functionResponse: unknown = null;
    if (functionHelloUrl) {
      const fnRes = await fetch(functionHelloUrl);
      functionResponse = await fnRes.json();
    }

    return {
      data: {
        status: 'ok',
        branch: this.config.get<string>('NEON_BRANCH') ?? 'production',
        postgres: {
          connected: true,
          database: dbRows[0]?.database ?? 'neondb',
          usersCount: Number(dbRows[0]?.user_count ?? 0),
        },
        neonAuth: {
          configured: Boolean(authBaseUrl && authJwksUrl),
          baseUrl: authBaseUrl,
          jwksUrl: authJwksUrl,
          jwksKeysCount,
        },
        functions: {
          helloUrl: functionHelloUrl,
          helloStatus: functionResponse,
        },
        timestamp: new Date().toISOString(),
      },
    };
  }
}

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env', '../.env.local', '../.env'],
    }),
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          ttl: Number(config.get('THROTTLE_TTL_MS') ?? 60_000),
          limit: Number(config.get('THROTTLE_LIMIT') ?? 60),
        },
      ],
    }),
    PrismaModule,
    AuthModule,
    TasksModule,
    HabitsModule,
    CalendarModule,
    DashboardModule,
    RemindersModule,
    StatisticsModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
