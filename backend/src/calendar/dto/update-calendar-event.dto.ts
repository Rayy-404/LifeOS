import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsISO8601,
  IsOptional,
  IsString,
  Length,
  MaxLength,
  ValidateIf,
} from 'class-validator';

/**
 * `PATCH /api/v1/calendar/events/:id` request payload (`03-technical-spec.md` Section 4.4).
 */
export class UpdateCalendarEventDto {
  @ApiPropertyOptional({
    example: 'Belajar pemrograman lanjutan',
    minLength: 1,
    maxLength: 200,
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

  @ApiPropertyOptional({
    example: 'Membahas state management Riverpod',
    maxLength: 5000,
    nullable: true,
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @ValidateIf((_, value) => value !== undefined && value !== null)
  @IsString()
  @MaxLength(5000)
  description?: string | null;

  @ApiPropertyOptional({
    example: 'Perpustakaan Pusat',
    maxLength: 300,
    nullable: true,
  })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @ValidateIf((_, value) => value !== undefined && value !== null)
  @IsString()
  @MaxLength(300)
  location?: string | null;

  @ApiPropertyOptional({
    example: '2026-10-18T01:00:00.000Z',
  })
  @IsOptional()
  @IsISO8601()
  startsAt?: string;

  @ApiPropertyOptional({
    example: '2026-10-18T03:00:00.000Z',
  })
  @IsOptional()
  @IsISO8601()
  endsAt?: string;
}
