import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches } from 'class-validator';

/**
 * Query parameters for `GET /api/v1/statistics/overview?from=YYYY-MM-DD&to=YYYY-MM-DD`
 * (`03-technical-spec.md` Section 4.6). `to` is inclusive as a calendar date and
 * is converted to the half-open UTC interval `[from 00:00, to + 1 day 00:00)`.
 */
export class StatisticsRangeQueryDto {
  @ApiProperty({ example: '2026-10-12' })
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '"from" must be in YYYY-MM-DD format',
  })
  from!: string;

  @ApiProperty({ example: '2026-10-18' })
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '"to" must be in YYYY-MM-DD format',
  })
  to!: string;
}
