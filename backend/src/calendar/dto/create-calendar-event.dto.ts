import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsISO8601,
  IsOptional,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';

/**
 * `POST /api/v1/calendar/events` request payload (`03-technical-spec.md` Section 4.4).
 */
export class CreateCalendarEventDto {
  @ApiProperty({
    example: 'Belajar pemrograman',
    minLength: 1,
    maxLength: 200,
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiPropertyOptional({
    example: 'Membahas arsitektur NestJS & Flutter',
    maxLength: 5000,
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  description?: string | null;

  @ApiPropertyOptional({
    example: 'Gedung B R.204',
    maxLength: 300,
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsOptional()
  @IsString()
  @MaxLength(300)
  location?: string | null;

  @ApiProperty({
    example: '2026-10-18T01:00:00.000Z',
    description: 'Event start timestamp in ISO-8601 format',
  })
  @IsISO8601()
  startsAt!: string;

  @ApiProperty({
    example: '2026-10-18T03:00:00.000Z',
    description: 'Event end timestamp in ISO-8601 format (must be > startsAt)',
  })
  @IsISO8601()
  endsAt!: string;
}
