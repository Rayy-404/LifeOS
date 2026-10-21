import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  CalendarEvent,
  Reminder,
  ReminderChannel,
  ReminderStatus,
  Task,
} from '@prisma/client';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReminderDto } from './dto/create-reminder.dto';
import { ListRemindersQueryDto } from './dto/list-reminders-query.dto';
import { UpdateReminderDto } from './dto/update-reminder.dto';

export type ReminderTargetTask = Pick<Task, 'id' | 'title' | 'status' | 'dueAt'>;
export type ReminderTargetEvent = Pick<
  CalendarEvent,
  'id' | 'title' | 'startsAt' | 'endsAt'
>;

export type ReminderWithTarget = Reminder & {
  task: ReminderTargetTask | null;
  event: ReminderTargetEvent | null;
};

const TARGET_INCLUDE = {
  task: {
    select: { id: true, title: true, status: true, dueAt: true },
  },
  event: {
    select: { id: true, title: true, startsAt: true, endsAt: true },
  },
} as const;

/**
 * Reminder lifecycle service (`03-technical-spec.md` Sections 3.2 & 4.5,
 * `04-architecture-security-testing.md` §12.3, OD-01/OD-04):
 * - enforces XOR target exclusivity and cross-tenant ownership (`404`, never `403`)
 * - only accepts future `remindAt` for `SCHEDULED` reminders
 * - automatically restores `SCHEDULED` when `remindAt` moves into the future
 */
@Injectable()
export class RemindersService {
  constructor(private readonly prisma: PrismaService) {}

  async list(
    user: AuthenticatedUser,
    query: ListRemindersQueryDto = {},
  ): Promise<ReminderWithTarget[]> {
    return this.prisma.reminder.findMany({
      where: {
        userId: user.id,
        ...(query.status ? { status: query.status } : {}),
      },
      include: TARGET_INCLUDE,
      orderBy: { remindAt: 'asc' },
    });
  }

  async create(
    user: AuthenticatedUser,
    dto: CreateReminderDto,
  ): Promise<ReminderWithTarget> {
    const hasTask = typeof dto.taskId === 'string' && dto.taskId.length > 0;
    const hasEvent =
      typeof dto.eventId === 'string' && dto.eventId.length > 0;

    if (hasTask === hasEvent) {
      throw new BadRequestException({
        code: 'REMINDER_TARGET_XOR_VIOLATION',
        message:
          'A reminder must reference exactly one of "taskId" or "eventId".',
      });
    }

    const remindAt = this.parseFutureRemindAt(dto.remindAt);

    if (hasTask) {
      await this.assertTaskOwnership(user.id, dto.taskId as string);
    } else {
      await this.assertEventOwnership(user.id, dto.eventId as string);
    }

    return this.prisma.reminder.create({
      data: {
        userId: user.id,
        taskId: hasTask ? dto.taskId : null,
        eventId: hasEvent ? dto.eventId : null,
        remindAt,
        channel: dto.channel ?? ReminderChannel.LOCAL,
        status: ReminderStatus.SCHEDULED,
      },
      include: TARGET_INCLUDE,
    });
  }

  async update(
    user: AuthenticatedUser,
    reminderId: string,
    dto: UpdateReminderDto,
  ): Promise<ReminderWithTarget> {
    const existing = await this.prisma.reminder.findFirst({
      where: { id: reminderId, userId: user.id },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Reminder not found',
      });
    }

    const data: {
      remindAt?: Date;
      status?: ReminderStatus;
      channel?: ReminderChannel;
    } = {};

    if (dto.channel !== undefined) {
      data.channel = dto.channel;
    }

    if (dto.remindAt !== undefined) {
      data.remindAt = this.parseFutureRemindAt(dto.remindAt);
      data.status = ReminderStatus.SCHEDULED;
    } else if (dto.status !== undefined) {
      data.status = dto.status;
    }

    return this.prisma.reminder.update({
      where: { id: reminderId },
      data,
      include: TARGET_INCLUDE,
    });
  }

  async remove(
    user: AuthenticatedUser,
    reminderId: string,
  ): Promise<{ id: string; deleted: boolean }> {
    const deleted = await this.prisma.reminder.deleteMany({
      where: { id: reminderId, userId: user.id },
    });

    if (deleted.count === 0) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Reminder not found',
      });
    }

    return { id: reminderId, deleted: true };
  }

  private parseFutureRemindAt(raw: string): Date {
    const remindAt = new Date(raw);
    if (isNaN(remindAt.getTime())) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: 'Invalid ISO-8601 timestamp for remindAt.',
      });
    }
    if (remindAt.getTime() <= Date.now()) {
      throw new BadRequestException({
        code: 'INVALID_REMINDER_TIME',
        message: '"remindAt" must be strictly in the future.',
      });
    }
    return remindAt;
  }

  private async assertTaskOwnership(
    userId: string,
    taskId: string,
  ): Promise<void> {
    const task = await this.prisma.task.findFirst({
      where: { id: taskId, userId },
      select: { id: true },
    });
    if (!task) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Task not found',
      });
    }
  }

  private async assertEventOwnership(
    userId: string,
    eventId: string,
  ): Promise<void> {
    const event = await this.prisma.calendarEvent.findFirst({
      where: { id: eventId, userId },
      select: { id: true },
    });
    if (!event) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Calendar event not found',
      });
    }
  }
}
