import { ApiPropertyOptional } from '@nestjs/swagger';
import { Priority, TaskStatus } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsISO8601,
  IsOptional,
  IsString,
  Length,
  MaxLength,
  ValidateIf,
} from 'class-validator';

/**
 * `PATCH /api/v1/tasks/:id` request payload (`03-technical-spec.md` Section 4.2).
 * Allows clearing nullable fields (`description: null`, `dueAt: null`).
 */
export class UpdateTaskDto {
  @ApiPropertyOptional({
    example: 'Menyelesaikan proyek Flutter',
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
    example: 'Implementasi task manager',
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

  @ApiPropertyOptional({ enum: TaskStatus })
  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @ApiPropertyOptional({ enum: Priority })
  @IsOptional()
  @IsEnum(Priority)
  priority?: Priority;

  @ApiPropertyOptional({
    example: '2026-10-20T12:00:00.000Z',
    nullable: true,
  })
  @ValidateIf((_, value) => value !== undefined && value !== null)
  @IsISO8601()
  dueAt?: string | null;
}
