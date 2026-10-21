import { ApiPropertyOptional } from '@nestjs/swagger';
import { ReminderStatus } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';

/**
 * Query parameters for `GET /api/v1/reminders?status=SCHEDULED`
 * (`03-technical-spec.md` Section 4.5). Results are always ordered by
 * `remindAt ASC`.
 */
export class ListRemindersQueryDto {
  @ApiPropertyOptional({ enum: ReminderStatus })
  @IsOptional()
  @IsEnum(ReminderStatus)
  status?: ReminderStatus;
}
