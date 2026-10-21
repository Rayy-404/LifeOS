import { ApiPropertyOptional } from '@nestjs/swagger';
import { ReminderChannel, ReminderStatus } from '@prisma/client';
import { IsEnum, IsISO8601, IsOptional } from 'class-validator';

/**
 * `PATCH /api/v1/reminders/:id` request payload (`03-technical-spec.md` Section 4.5).
 * Moving `remindAt` into the future automatically restores `status = SCHEDULED`.
 * The reminder target (`taskId` / `eventId`) cannot be changed after creation.
 */
export class UpdateReminderDto {
  @ApiPropertyOptional({
    example: '2026-10-19T09:30:00+07:00',
    description:
      'New reminder timestamp in ISO-8601 format. Must be in the future; ' +
      'status is automatically set back to SCHEDULED.',
  })
  @IsOptional()
  @IsISO8601()
  remindAt?: string;

  @ApiPropertyOptional({ enum: ReminderStatus })
  @IsOptional()
  @IsEnum(ReminderStatus)
  status?: ReminderStatus;

  @ApiPropertyOptional({ enum: ReminderChannel })
  @IsOptional()
  @IsEnum(ReminderChannel)
  channel?: ReminderChannel;
}
