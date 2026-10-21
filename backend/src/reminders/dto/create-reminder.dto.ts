import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReminderChannel } from '@prisma/client';
import { IsEnum, IsISO8601, IsOptional, IsUUID } from 'class-validator';

/**
 * `POST /api/v1/reminders` request payload (`03-technical-spec.md` Section 4.5).
 * Exactly one of `taskId` / `eventId` must be provided; the XOR invariant is
 * enforced in `RemindersService` so the client receives
 * `400 REMINDER_TARGET_XOR_VIOLATION`.
 */
export class CreateReminderDto {
  @ApiPropertyOptional({
    example: '11111111-1111-4111-8111-111111111111',
    description: 'Target task UUID (mutually exclusive with eventId)',
  })
  @IsOptional()
  @IsUUID()
  taskId?: string;

  @ApiPropertyOptional({
    example: '22222222-2222-4222-8222-222222222222',
    description: 'Target calendar event UUID (mutually exclusive with taskId)',
  })
  @IsOptional()
  @IsUUID()
  eventId?: string;

  @ApiProperty({
    example: '2026-10-19T08:00:00+07:00',
    description:
      'Reminder timestamp in ISO-8601 format. Must be strictly in the future.',
  })
  @IsISO8601()
  remindAt!: string;

  @ApiPropertyOptional({
    enum: ReminderChannel,
    default: ReminderChannel.LOCAL,
  })
  @IsOptional()
  @IsEnum(ReminderChannel)
  channel?: ReminderChannel;
}
