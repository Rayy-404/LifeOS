import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

/**
 * `PUT /api/v1/habits/:id/logs/:date` request payload (`03-technical-spec.md` Section 4.3).
 */
export class CheckInHabitDto {
  @ApiProperty({
    example: true,
    description: 'Set true to record completion, false to remove completion log',
  })
  @IsBoolean()
  completed!: boolean;
}
