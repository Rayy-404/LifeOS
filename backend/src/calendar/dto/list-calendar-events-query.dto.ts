import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

/**
 * Query parameters for `GET /api/v1/calendar/events?from=...&to=...`.
 * Supports either `YYYY-MM-DD` calendar dates (interpreted in `user.timezone`)
 * or full ISO-8601 timestamps.
 */
export class ListCalendarEventsQueryDto {
  @ApiPropertyOptional({
    example: '2026-10-18',
    description: 'Start date (YYYY-MM-DD) or ISO-8601 timestamp',
  })
  @IsOptional()
  @IsString()
  from?: string;

  @ApiPropertyOptional({
    example: '2026-10-18',
    description: 'End date (YYYY-MM-DD) or ISO-8601 timestamp',
  })
  @IsOptional()
  @IsString()
  to?: string;
}
