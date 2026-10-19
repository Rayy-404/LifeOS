import { Controller, Get, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { PrismaModule } from './prisma/prisma.module';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Check API health status' })
  check() {
    return {
      data: {
        status: 'ok',
        service: 'lifeos-backend',
        timestamp: new Date().toISOString(),
      },
    };
  }
}

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 60,
      },
    ]),
    PrismaModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
