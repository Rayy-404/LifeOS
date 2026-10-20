import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, Matches } from 'class-validator';

/**
 * Query parameters for `GET /api/v1/dashboard/today?date=YYYY-MM-DD`.
 */
export class GetDashboardTodayQueryDto {
  @ApiPropertyOptional({
    example: '2026-10-18',
    description:
      'Target calendar date in YYYY-MM-DD format (interpreted in user.timezone)',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '"date" must be in YYYY-MM-DD format',
  })
  date?: string;
}
