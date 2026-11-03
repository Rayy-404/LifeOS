import { BadRequestException, Injectable } from '@nestjs/common';
import { TaskStatus } from '@prisma/client';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';
import { DateRangeHelper } from '../common/utils/date-range.helper';
import { PrismaService } from '../prisma/prisma.service';
import { StatisticsRangeQueryDto } from './dto/statistics-range-query.dto';
import { WeeklyStatisticsQueryDto } from './dto/weekly-statistics-query.dto';

export interface StatisticsTaskMetrics {
  total: number;
  completed: number;
  overdue: number;
  completionRate: number;
}

export interface StatisticsHabitMetrics {
  totalScheduledInstances: number;
  totalCompletedInstances: number;
  consistencyRate: number;
}

export interface StatisticsOverviewResult {
  from: string;
  to: string;
  tasks: StatisticsTaskMetrics;
  habits: StatisticsHabitMetrics;
}

export interface WeeklyStatisticsDay {
  date: string;
  isoWeekday: number;
  tasksCompleted: number;
  habitsScheduled: number;
  habitsCompleted: number;
}

export interface WeeklyStatisticsResult {
  weekStart: string;
  weekEnd: string;
  days: WeeklyStatisticsDay[];
}

const TASK_SELECT = {
  status: true,
  dueAt: true,
  completedAt: true,
} as const;

/**
 * Statistics aggregation service (`01-prd.md` FR-STAT-01..02 &
 * `03-technical-spec.md` §4.6). All calendar calculations follow the user's
 * timezone and the half-open UTC interval `[startUtc, endUtc)` from
 * `DateRangeHelper` (OD-05).
 *
 * Overview definitions (documented in `03-technical-spec.md` §4.6):
 * - `tasks.total`: union of tasks whose `dueAt` intersects the range or whose
 *   `completedAt` falls inside the range.
 * - `tasks.completed`: `DONE` tasks within that union.
 * - `tasks.overdue`: unfinished tasks in the union whose `dueAt < now`.
 * - `habits.totalScheduledInstances`: `activeDays` occurrences of every active
 *   habit across the inclusive `[from, to]` calendar dates.
 * - `habits.totalCompletedInstances`: check-ins on those scheduled weekdays.
 */
@Injectable()
export class StatisticsService {
  constructor(private readonly prisma: PrismaService) {}

  async getOverview(
    user: AuthenticatedUser,
    query: StatisticsRangeQueryDto,
    now: Date = new Date(),
  ): Promise<StatisticsOverviewResult> {
    const { from, to } = query;
    const { startUtc, endUtc } = DateRangeHelper.getRangeUtcInterval(
      from,
      to,
      user.timezone,
    );
    const fromDate = this.toDateOnlyDate(from);
    const toDate = this.toDateOnlyDate(to);

    const tasks = await this.prisma.task.findMany({
      where: {
        userId: user.id,
        OR: [
          { dueAt: { gte: startUtc, lt: endUtc } },
          { completedAt: { gte: startUtc, lt: endUtc } },
        ],
      },
      select: TASK_SELECT,
    });

    const habits = await this.prisma.habit.findMany({
      where: { userId: user.id, isActive: true },
      select: {
        id: true,
        activeDays: true,
        logs: {
          where: { logDate: { gte: fromDate, lte: toDate } },
          select: { logDate: true },
        },
      },
    });

    const total = tasks.length;
    const completed = tasks.filter(
      (task) => task.status === TaskStatus.DONE,
    ).length;
    const overdue = tasks.filter(
      (task) =>
        task.status !== TaskStatus.DONE &&
        task.dueAt !== null &&
        task.dueAt.getTime() < now.getTime(),
    ).length;

    let totalScheduledInstances = 0;
    let totalCompletedInstances = 0;

    for (const habit of habits) {
      totalScheduledInstances += this.countActiveDaysInRange(
        habit.activeDays,
        from,
        to,
      );
      totalCompletedInstances += habit.logs.filter((log) =>
        habit.activeDays.includes(
          DateRangeHelper.getIsoWeekday(this.toDateOnlyString(log.logDate)),
        ),
      ).length;
    }

    return {
      from,
      to,
      tasks: {
        total,
        completed,
        overdue,
        completionRate: StatisticsService.percentage(completed, total),
      },
      habits: {
        totalScheduledInstances,
        totalCompletedInstances,
        consistencyRate: StatisticsService.percentage(
          totalCompletedInstances,
          totalScheduledInstances,
        ),
      },
    };
  }

  async getWeekly(
    user: AuthenticatedUser,
    query: WeeklyStatisticsQueryDto,
  ): Promise<WeeklyStatisticsResult> {
    const { weekStart } = query;
    const weekEnd = DateRangeHelper.addDaysToDateString(weekStart, 6);
    const { startUtc, endUtc } = DateRangeHelper.getRangeUtcInterval(
      weekStart,
      weekEnd,
      user.timezone,
    );
    const fromDate = this.toDateOnlyDate(weekStart);
    const toDate = this.toDateOnlyDate(weekEnd);

    const completedTasks = await this.prisma.task.findMany({
      where: {
        userId: user.id,
        completedAt: { gte: startUtc, lt: endUtc },
      },
      select: { completedAt: true },
    });

    const habits = await this.prisma.habit.findMany({
      where: { userId: user.id, isActive: true },
      select: {
        id: true,
        activeDays: true,
        logs: {
          where: { logDate: { gte: fromDate, lte: toDate } },
          select: { logDate: true },
        },
      },
    });

    const tasksCompletedByDate = new Map<string, number>();
    for (const task of completedTasks) {
      if (!task.completedAt) continue;
      const key = DateRangeHelper.getTodayLocalDateString(
        user.timezone,
        task.completedAt,
      );
      tasksCompletedByDate.set(key, (tasksCompletedByDate.get(key) ?? 0) + 1);
    }

    const habitsCompletedByDate = new Map<string, number>();
    for (const habit of habits) {
      for (const log of habit.logs) {
        const dateStr = this.toDateOnlyString(log.logDate);
        if (
          !habit.activeDays.includes(DateRangeHelper.getIsoWeekday(dateStr))
        ) {
          continue;
        }
        habitsCompletedByDate.set(
          dateStr,
          (habitsCompletedByDate.get(dateStr) ?? 0) + 1,
        );
      }
    }

    const days: WeeklyStatisticsDay[] = [];
    for (let offset = 0; offset < 7; offset += 1) {
      const date = DateRangeHelper.addDaysToDateString(weekStart, offset);
      const isoWeekday = DateRangeHelper.getIsoWeekday(date);
      days.push({
        date,
        isoWeekday,
        tasksCompleted: tasksCompletedByDate.get(date) ?? 0,
        habitsScheduled: habits.filter((habit) =>
          habit.activeDays.includes(isoWeekday),
        ).length,
        habitsCompleted: habitsCompletedByDate.get(date) ?? 0,
      });
    }

    return { weekStart, weekEnd, days };
  }

  private static percentage(numerator: number, denominator: number): number {
    if (denominator <= 0) return 0;
    return Math.round((numerator / denominator) * 1000) / 10;
  }

  private countActiveDaysInRange(
    activeDays: number[],
    from: string,
    to: string,
  ): number {
    let count = 0;
    let cursor = from;
    while (cursor <= to) {
      if (activeDays.includes(DateRangeHelper.getIsoWeekday(cursor))) {
        count += 1;
      }
      cursor = DateRangeHelper.addDaysToDateString(cursor, 1);
    }
    return count;
  }

  private toDateOnlyDate(dateStr: string): Date {
    const parsed = new Date(`${dateStr}T00:00:00.000Z`);
    if (isNaN(parsed.getTime())) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: `Invalid calendar date "${dateStr}".`,
      });
    }
    return parsed;
  }

  private toDateOnlyString(date: Date): string {
    return date.toISOString().slice(0, 10);
  }
}
