import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, Matches } from 'class-validator';

/**
 * Query parameters for `GET /api/v1/habits/:id/logs?from=YYYY-MM-DD&to=YYYY-MM-DD`.
 */
export class ListHabitLogsQueryDto {
  @ApiPropertyOptional({
    example: '2026-10-12',
    description: 'Start date in YYYY-MM-DD format',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '"from" must be in YYYY-MM-DD format',
  })
  from?: string;

  @ApiPropertyOptional({
    example: '2026-10-18',
    description: 'End date in YYYY-MM-DD format',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '"to" must be in YYYY-MM-DD format',
  })
  to?: string;
}
