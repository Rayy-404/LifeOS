import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches } from 'class-validator';

/**
 * Query parameters for `GET /api/v1/statistics/weekly?weekStart=YYYY-MM-DD`
 * (`03-technical-spec.md` Section 4.6). Always returns exactly 7 days from
 * `weekStart` through `weekStart + 6`.
 */
export class WeeklyStatisticsQueryDto {
  @ApiProperty({ example: '2026-10-12' })
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '"weekStart" must be in YYYY-MM-DD format',
  })
  weekStart!: string;
}
