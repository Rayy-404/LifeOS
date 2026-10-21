import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CalendarEvent, Prisma, Reminder, Task } from '@prisma/client';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';
import { DateRangeHelper } from '../common/utils/date-range.helper';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto';
import { ListCalendarEventsQueryDto } from './dto/list-calendar-events-query.dto';
import { UpdateCalendarEventDto } from './dto/update-calendar-event.dto';

export type CalendarEventItem = CalendarEvent & {
  type: 'EVENT';
};

export type CalendarTaskItem = Task & {
  type: 'TASK';
};

export type CalendarEventWithReminders = CalendarEvent & {
  reminders: Reminder[];
};

export interface CalendarAgendaResult {
  from: string;
  to: string;
  events: CalendarEventItem[];
  tasks: CalendarTaskItem[];
}

/**
 * Calendar & Scheduled Events service (`03-technical-spec.md` Sections 3.3 & 4.4):
 * - Enforces Zero IDOR (`userId` ownership on all queries)
 * - Enforces strict time order `endsAt > startsAt` (`400 INVALID_TIME_RANGE`)
 * - Returns combined agenda of overlapping `CalendarEvent` (`startsAt < endUtc AND endsAt > startUtc`)
 *   and `Task` (`dueAt >= startUtc AND dueAt < endUtc`) with `type: 'EVENT' | 'TASK'` discriminators
 */
@Injectable()
export class CalendarService {
  constructor(private readonly prisma: PrismaService) {}

  static assertValidTimeOrder(startsAt: Date, endsAt: Date): void {
    if (isNaN(startsAt.getTime()) || isNaN(endsAt.getTime())) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: 'Invalid ISO-8601 timestamp for startsAt or endsAt.',
      });
    }
    if (endsAt <= startsAt) {
      throw new BadRequestException({
        code: 'INVALID_TIME_RANGE',
        message: '"endsAt" must be strictly greater than "startsAt".',
      });
    }
  }

  async listAgenda(
    user: AuthenticatedUser,
    query: ListCalendarEventsQueryDto = {},
    now: Date = new Date(),
  ): Promise<CalendarAgendaResult> {
    const todayLocal = DateRangeHelper.getTodayLocalDateString(
      user.timezone,
      now,
    );
    const from = query.from ?? todayLocal;
    const to = query.to ?? from;

    const { startUtc, endUtc } = DateRangeHelper.getRangeUtcInterval(
      from,
      to,
      user.timezone,
    );

    const [events, tasks] = await Promise.all([
      this.prisma.calendarEvent.findMany({
        where: {
          userId: user.id,
          startsAt: { lt: endUtc },
          endsAt: { gt: startUtc },
        },
        include: {
          reminders: {
            select: { id: true, status: true },
          },
        },
        orderBy: { startsAt: 'asc' },
      }),
      this.prisma.task.findMany({
        where: {
          userId: user.id,
          dueAt: {
            gte: startUtc,
            lt: endUtc,
          },
        },
        include: {
          reminders: {
            select: { id: true, status: true },
          },
        },
        orderBy: { dueAt: 'asc' },
      }),
    ]);

    return {
      from,
      to,
      events: events.map((event) => ({
        ...event,
        type: 'EVENT' as const,
      })),
      tasks: tasks.map((task) => ({
        ...task,
        type: 'TASK' as const,
      })),
    };
  }

  async create(
    userId: string,
    dto: CreateCalendarEventDto,
  ): Promise<CalendarEvent> {
    const startsAt = new Date(dto.startsAt);
    const endsAt = new Date(dto.endsAt);
    CalendarService.assertValidTimeOrder(startsAt, endsAt);

    return this.prisma.calendarEvent.create({
      data: {
        userId,
        title: dto.title.trim(),
        description: dto.description ?? null,
        location: dto.location ?? null,
        startsAt,
        endsAt,
      },
    });
  }

  async findOne(
    userId: string,
    eventId: string,
  ): Promise<CalendarEventWithReminders> {
    const event = await this.prisma.calendarEvent.findFirst({
      where: {
        id: eventId,
        userId,
      },
      include: {
        reminders: {
          orderBy: { remindAt: 'asc' },
        },
      },
    });

    if (!event) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Calendar event not found',
      });
    }

    return event;
  }

  async update(
    userId: string,
    eventId: string,
    dto: UpdateCalendarEventDto,
  ): Promise<CalendarEvent> {
    const existing = await this.prisma.calendarEvent.findFirst({
      where: {
        id: eventId,
        userId,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Calendar event not found',
      });
    }

    const nextStartsAt =
      dto.startsAt !== undefined ? new Date(dto.startsAt) : existing.startsAt;
    const nextEndsAt =
      dto.endsAt !== undefined ? new Date(dto.endsAt) : existing.endsAt;

    CalendarService.assertValidTimeOrder(nextStartsAt, nextEndsAt);

    const data: Prisma.CalendarEventUpdateInput = {
      startsAt: nextStartsAt,
      endsAt: nextEndsAt,
    };

    if (dto.title !== undefined) {
      data.title = dto.title.trim();
    }
    if (dto.description !== undefined) {
      data.description = dto.description;
    }
    if (dto.location !== undefined) {
      data.location = dto.location;
    }

    return this.prisma.calendarEvent.update({
      where: { id: eventId },
      data,
    });
  }

  async remove(
    userId: string,
    eventId: string,
  ): Promise<{ id: string; deleted: boolean }> {
    const deleted = await this.prisma.calendarEvent.deleteMany({
      where: {
        id: eventId,
        userId,
      },
    });

    if (deleted.count === 0) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Calendar event not found',
      });
    }

    return { id: eventId, deleted: true };
  }
}
