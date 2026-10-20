import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Habit, HabitLog, Prisma } from '@prisma/client';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';
import { DateRangeHelper } from '../common/utils/date-range.helper';
import { PrismaService } from '../prisma/prisma.service';
import { CheckInHabitDto } from './dto/check-in-habit.dto';
import { CreateHabitDto } from './dto/create-habit.dto';
import { ListHabitLogsQueryDto } from './dto/list-habit-logs-query.dto';
import { ListHabitsQueryDto } from './dto/list-habits-query.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';

export interface WeeklyHabitLogItem {
  date: string;
  isoWeekday: number;
  scheduled: boolean;
  completed: boolean;
}

export interface HabitWithMetrics extends Habit {
  currentStreak: number;
  completedToday: boolean;
  weeklyLogs: WeeklyHabitLogItem[];
}

export interface HabitLogItem {
  id: string;
  habitId: string;
  logDate: string;
  completedAt: Date | null;
  createdAt: Date;
}

export interface CheckInResult {
  habitId: string;
  logDate: string;
  completed: boolean;
  completedAt: Date | null;
  currentStreak: number;
}

/**
 * Habit Tracker service (`03-technical-spec.md` Sections 3, 3.1 & 4.3):
 * - Enforces Zero IDOR (`userId` ownership on all queries)
 * - Canonicalizes `activeDays` (`1..7` sorted unique integers)
 * - Deterministic `currentStreak` calculation ignoring non-scheduled days
 * - Idempotent daily check-in (`PUT /habits/:id/logs/:date`) with future date rejection
 *   and H-7 backfill window (`01-prd.md` Section 10 #2)
 */
@Injectable()
export class HabitsService {
  private static readonly DATE_ONLY_REGEX = /^\d{4}-\d{2}-\d{2}$/;
  private static readonly DEFAULT_ACTIVE_DAYS = [1, 2, 3, 4, 5, 6, 7];
  private static readonly MAX_BACKFILL_DAYS = 7;

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Validates and canonicalizes `activeDays` into sorted ascending unique ISO weekdays `1..7`.
   */
  static normalizeActiveDays(days?: number[]): number[] {
    const input = days ?? this.DEFAULT_ACTIVE_DAYS;
    if (!Array.isArray(input) || input.length < 1 || input.length > 7) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: 'activeDays must be a non-empty array of 1 to 7 weekdays.',
      });
    }

    for (const day of input) {
      if (!Number.isInteger(day) || day < 1 || day > 7) {
        throw new BadRequestException({
          code: 'VALIDATION_ERROR',
          message: 'Each activeDay must be an integer between 1 and 7.',
        });
      }
    }

    const unique = [...new Set(input)];
    if (unique.length !== input.length) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: 'activeDays must not contain duplicate weekdays.',
      });
    }

    return unique.sort((a, b) => a - b);
  }

  /**
   * Deterministic `currentStreak` calculation (`03-technical-spec.md` Section 3.1):
   * 1. `todayLocal` is the current calendar date (`YYYY-MM-DD`) in `user.timezone`.
   * 2. A date `d` is a scheduled day iff `isoWeekday(d)` is in `activeDays`.
   *    Non-scheduled days are skipped and never break the streak.
   * 3. If `todayLocal` is scheduled and completed -> streak starts at 1, then checks backwards.
   *    If `todayLocal` is scheduled and NOT completed -> streak does not reset to 0;
   *    backward iteration starts from the previous scheduled day before `todayLocal`.
   *    If `todayLocal` is not scheduled -> backward iteration starts from the previous scheduled day.
   * 4. Future logs (`logDate > todayLocal`) are always ignored.
   */
  static calculateStreak(
    activeDays: number[],
    completedDateStrings: Iterable<string>,
    todayLocal: string,
  ): number {
    if (!activeDays || activeDays.length === 0) {
      return 0;
    }

    const activeSet = new Set(activeDays);
    const validCompleted = new Set<string>();
    let minCompletedDate: string | null = null;

    for (const raw of completedDateStrings) {
      const dateStr = raw.slice(0, 10);
      if (dateStr <= todayLocal) {
        validCompleted.add(dateStr);
        if (minCompletedDate === null || dateStr < minCompletedDate) {
          minCompletedDate = dateStr;
        }
      }
    }

    if (validCompleted.size === 0 || minCompletedDate === null) {
      return 0;
    }

    let streak = 0;
    const todayWeekday = DateRangeHelper.getIsoWeekday(todayLocal);
    if (activeSet.has(todayWeekday) && validCompleted.has(todayLocal)) {
      streak = 1;
    }

    let cursor = DateRangeHelper.addDaysToDateString(todayLocal, -1);
    while (cursor >= minCompletedDate) {
      const weekday = DateRangeHelper.getIsoWeekday(cursor);
      if (activeSet.has(weekday)) {
        if (validCompleted.has(cursor)) {
          streak += 1;
        } else {
          break;
        }
      }
      cursor = DateRangeHelper.addDaysToDateString(cursor, -1);
    }

    return streak;
  }

  /**
   * Builds the 7-day ISO week (`Monday = 1` .. `Sunday = 7`) containing `todayLocal`.
   */
  static buildWeeklyLogs(
    activeDays: number[],
    completedDateStrings: ReadonlySet<string>,
    todayLocal: string,
  ): WeeklyHabitLogItem[] {
    const activeSet = new Set(activeDays);
    const todayWeekday = DateRangeHelper.getIsoWeekday(todayLocal);
    const mondayDate = DateRangeHelper.addDaysToDateString(
      todayLocal,
      -(todayWeekday - 1),
    );

    const items: WeeklyHabitLogItem[] = [];
    for (let i = 0; i < 7; i++) {
      const date = DateRangeHelper.addDaysToDateString(mondayDate, i);
      const isoWeekday = i + 1;
      items.push({
        date,
        isoWeekday,
        scheduled: activeSet.has(isoWeekday),
        completed: completedDateStrings.has(date),
      });
    }
    return items;
  }

  static toDateOnlyString(date: Date | string): string {
    if (typeof date === 'string') {
      return date.slice(0, 10);
    }
    return date.toISOString().slice(0, 10);
  }

  private static parseCalendarDate(dateStr: string, fieldName = 'date'): Date {
    if (!this.DATE_ONLY_REGEX.test(dateStr)) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: `Invalid ${fieldName} format "${dateStr}". Expected YYYY-MM-DD.`,
      });
    }
    const [y, m, d] = dateStr.split('-').map(Number);
    const dt = new Date(Date.UTC(y, m - 1, d));
    if (
      isNaN(dt.getTime()) ||
      dt.toISOString().slice(0, 10) !== dateStr
    ) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: `Invalid calendar ${fieldName} "${dateStr}".`,
      });
    }
    return dt;
  }

  private enrichHabit(
    habit: Habit & { logs: HabitLog[] },
    todayLocal: string,
  ): HabitWithMetrics {
    const completedSet = new Set<string>(
      habit.logs
        .map((l) => HabitsService.toDateOnlyString(l.logDate))
        .filter((d) => d <= todayLocal),
    );

    const currentStreak = HabitsService.calculateStreak(
      habit.activeDays,
      completedSet,
      todayLocal,
    );
    const completedToday = completedSet.has(todayLocal);
    const weeklyLogs = HabitsService.buildWeeklyLogs(
      habit.activeDays,
      completedSet,
      todayLocal,
    );

    const { logs: _logs, ...rest } = habit;
    return {
      ...rest,
      currentStreak,
      completedToday,
      weeklyLogs,
    };
  }

  async list(
    user: AuthenticatedUser,
    query: ListHabitsQueryDto = {},
    now: Date = new Date(),
  ): Promise<HabitWithMetrics[]> {
    const todayLocal = DateRangeHelper.getTodayLocalDateString(
      user.timezone,
      now,
    );

    const where: Prisma.HabitWhereInput = {
      userId: user.id,
    };

    if (query.isActive !== undefined) {
      where.isActive = query.isActive;
    }

    const habits = await this.prisma.habit.findMany({
      where,
      include: {
        logs: {
          orderBy: { logDate: 'desc' },
        },
      },
      orderBy: [{ isActive: 'desc' }, { createdAt: 'asc' }],
    });

    return habits.map((habit) => this.enrichHabit(habit, todayLocal));
  }

  async create(
    user: AuthenticatedUser,
    dto: CreateHabitDto,
    now: Date = new Date(),
  ): Promise<HabitWithMetrics> {
    const activeDays = HabitsService.normalizeActiveDays(dto.activeDays);
    const todayLocal = DateRangeHelper.getTodayLocalDateString(
      user.timezone,
      now,
    );

    const created = await this.prisma.habit.create({
      data: {
        userId: user.id,
        name: dto.name.trim(),
        description: dto.description ?? null,
        activeDays,
        isActive: dto.isActive ?? true,
      },
      include: {
        logs: true,
      },
    });

    return this.enrichHabit(created, todayLocal);
  }

  async findOne(
    user: AuthenticatedUser,
    habitId: string,
    now: Date = new Date(),
  ): Promise<HabitWithMetrics> {
    const todayLocal = DateRangeHelper.getTodayLocalDateString(
      user.timezone,
      now,
    );

    const habit = await this.prisma.habit.findFirst({
      where: {
        id: habitId,
        userId: user.id,
      },
      include: {
        logs: {
          orderBy: { logDate: 'desc' },
        },
      },
    });

    if (!habit) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Habit not found',
      });
    }

    return this.enrichHabit(habit, todayLocal);
  }

  async update(
    user: AuthenticatedUser,
    habitId: string,
    dto: UpdateHabitDto,
    now: Date = new Date(),
  ): Promise<HabitWithMetrics> {
    const existing = await this.prisma.habit.findFirst({
      where: {
        id: habitId,
        userId: user.id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Habit not found',
      });
    }

    const data: Prisma.HabitUpdateInput = {};

    if (dto.name !== undefined) {
      data.name = dto.name.trim();
    }
    if (dto.description !== undefined) {
      data.description = dto.description;
    }
    if (dto.activeDays !== undefined) {
      data.activeDays = HabitsService.normalizeActiveDays(dto.activeDays);
    }
    if (dto.isActive !== undefined) {
      data.isActive = dto.isActive;
    }

    const todayLocal = DateRangeHelper.getTodayLocalDateString(
      user.timezone,
      now,
    );

    const updated = await this.prisma.habit.update({
      where: { id: habitId },
      data,
      include: {
        logs: {
          orderBy: { logDate: 'desc' },
        },
      },
    });

    return this.enrichHabit(updated, todayLocal);
  }

  async remove(
    userId: string,
    habitId: string,
  ): Promise<{ id: string; deleted: boolean }> {
    const deleted = await this.prisma.habit.deleteMany({
      where: {
        id: habitId,
        userId,
      },
    });

    if (deleted.count === 0) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Habit not found',
      });
    }

    return { id: habitId, deleted: true };
  }

  /**
   * Idempotent daily check-in (`PUT /api/v1/habits/:id/logs/:date`).
   * - Rejects future dates (`logDate > todayLocal`) with `400 FUTURE_HABIT_LOG_NOT_ALLOWED`.
   * - Rejects backfill older than 7 days (`logDate < todayLocal - 7 days`).
   * - `completed = true`: upserts `(habitId, logDate)` setting `completedAt` if not already set.
   * - `completed = false`: deletes `(habitId, logDate)` cleanly with no orphan row.
   */
  async checkIn(
    user: AuthenticatedUser,
    habitId: string,
    dateStr: string,
    dto: CheckInHabitDto,
    now: Date = new Date(),
  ): Promise<CheckInResult> {
    const parsedLogDate = HabitsService.parseCalendarDate(dateStr, 'date');
    const todayLocal = DateRangeHelper.getTodayLocalDateString(
      user.timezone,
      now,
    );

    if (dateStr > todayLocal) {
      throw new BadRequestException({
        code: 'FUTURE_HABIT_LOG_NOT_ALLOWED',
        message: `Cannot record habit check-in for future date "${dateStr}" (today in ${user.timezone} is "${todayLocal}").`,
      });
    }

    const earliestBackfillDate = DateRangeHelper.addDaysToDateString(
      todayLocal,
      -HabitsService.MAX_BACKFILL_DAYS,
    );
    if (dateStr < earliestBackfillDate) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: `Backfill check-in is only allowed up to ${HabitsService.MAX_BACKFILL_DAYS} days in the past (earliest allowed: "${earliestBackfillDate}").`,
      });
    }

    const habit = await this.prisma.habit.findFirst({
      where: {
        id: habitId,
        userId: user.id,
      },
    });

    if (!habit) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Habit not found',
      });
    }

    let completedAt: Date | null = null;

    if (dto.completed) {
      const existingLog = await this.prisma.habitLog.findUnique({
        where: {
          habitId_logDate: {
            habitId,
            logDate: parsedLogDate,
          },
        },
      });

      const logRecord = await this.prisma.habitLog.upsert({
        where: {
          habitId_logDate: {
            habitId,
            logDate: parsedLogDate,
          },
        },
        create: {
          habitId,
          logDate: parsedLogDate,
          completedAt: now,
        },
        update: existingLog?.completedAt ? {} : { completedAt: now },
      });
      completedAt = logRecord.completedAt;
    } else {
      await this.prisma.habitLog.deleteMany({
        where: {
          habitId,
          logDate: parsedLogDate,
        },
      });
      completedAt = null;
    }

    const logs = await this.prisma.habitLog.findMany({
      where: { habitId },
      orderBy: { logDate: 'desc' },
    });

    const completedSet = new Set<string>(
      logs.map((l) => HabitsService.toDateOnlyString(l.logDate)),
    );
    const currentStreak = HabitsService.calculateStreak(
      habit.activeDays,
      completedSet,
      todayLocal,
    );

    return {
      habitId,
      logDate: dateStr,
      completed: dto.completed,
      completedAt,
      currentStreak,
    };
  }

  /**
   * Lists check-in logs for a habit (`GET /api/v1/habits/:id/logs?from=YYYY-MM-DD&to=YYYY-MM-DD`),
   * ordered by `logDate DESC`.
   */
  async getLogs(
    user: AuthenticatedUser,
    habitId: string,
    query: ListHabitLogsQueryDto = {},
  ): Promise<HabitLogItem[]> {
    const habit = await this.prisma.habit.findFirst({
      where: {
        id: habitId,
        userId: user.id,
      },
    });

    if (!habit) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Habit not found',
      });
    }

    const logDateFilter: Prisma.DateTimeFilter = {};

    if (query.from) {
      logDateFilter.gte = HabitsService.parseCalendarDate(query.from, 'from');
    }
    if (query.to) {
      logDateFilter.lte = HabitsService.parseCalendarDate(query.to, 'to');
    }
    if (query.from && query.to && query.from > query.to) {
      throw new BadRequestException({
        code: 'INVALID_TIME_RANGE',
        message: '"from" date must be less than or equal to "to" date.',
      });
    }

    const where: Prisma.HabitLogWhereInput = {
      habitId,
      ...(Object.keys(logDateFilter).length > 0
        ? { logDate: logDateFilter }
        : {}),
    };

    const logs = await this.prisma.habitLog.findMany({
      where,
      orderBy: { logDate: 'desc' },
    });

    return logs.map((l) => ({
      id: l.id,
      habitId: l.habitId,
      logDate: HabitsService.toDateOnlyString(l.logDate),
      completedAt: l.completedAt,
      createdAt: l.createdAt,
    }));
  }
}
