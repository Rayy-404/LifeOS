import { Injectable } from '@nestjs/common';
import { CalendarEvent, Priority, Task, TaskStatus } from '@prisma/client';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';
import { DateRangeHelper } from '../common/utils/date-range.helper';
import { HabitWithMetrics, HabitsService } from '../habits/habits.service';
import { PrismaService } from '../prisma/prisma.service';
import { GetDashboardTodayQueryDto } from './dto/get-dashboard-today-query.dto';

export interface DashboardTasksMetrics {
  total: number;
  completed: number;
  pending: number;
  overdue: number;
}

export interface DashboardHabitsMetrics {
  scheduled: number;
  completed: number;
}

export interface DashboardTodayResult {
  date: string;
  timezone: string;
  tasks: DashboardTasksMetrics;
  habits: DashboardHabitsMetrics;
  upcomingEvents: CalendarEvent[];
  todayTasks: Task[];
  todayHabits: HabitWithMetrics[];
}

/**
 * Dashboard Aggregation Service (`01-prd.md` FR-DASH-01..03, §10 #1 & `03-technical-spec.md` §4.6).
 */
@Injectable()
export class DashboardService {
  private static readonly PRIORITY_WEIGHT: Record<Priority, number> = {
    [Priority.HIGH]: 3,
    [Priority.MEDIUM]: 2,
    [Priority.LOW]: 1,
  };

  constructor(private readonly prisma: PrismaService) {}

  async getToday(
    user: AuthenticatedUser,
    query: GetDashboardTodayQueryDto = {},
    now: Date = new Date(),
  ): Promise<DashboardTodayResult> {
    const todayLocal = DateRangeHelper.getTodayLocalDateString(
      user.timezone,
      now,
    );
    const targetDate = query.date ?? todayLocal;
    const { startUtc, endUtc } = DateRangeHelper.getDayUtcInterval(
      targetDate,
      user.timezone,
    );
    const isoWeekday = DateRangeHelper.getIsoWeekday(targetDate);

    const [allUserTasks, upcomingEvents, activeHabits] = await Promise.all([
      this.prisma.task.findMany({
        where: { userId: user.id },
        include: {
          reminders: {
            select: { id: true, status: true },
          },
        },
      }),
      this.prisma.calendarEvent.findMany({
        where: {
          userId: user.id,
          startsAt: { lt: endUtc },
          endsAt: { gt: startUtc },
        },
        orderBy: { startsAt: 'asc' },
      }),
      this.prisma.habit.findMany({
        where: {
          userId: user.id,
          isActive: true,
        },
        include: {
          logs: {
            orderBy: { logDate: 'desc' },
          },
        },
        orderBy: { createdAt: 'asc' },
      }),
    ]);

    const overdueCutoff = targetDate === todayLocal ? now : startUtc;

    let completedCount = 0;
    let pendingCount = 0;
    let overdueCount = 0;
    const candidateTodayTasks: Task[] = [];

    for (const task of allUserTasks) {
      const isDone = task.status === TaskStatus.DONE;
      const isDueOnTargetDate =
        task.dueAt !== null &&
        task.dueAt >= startUtc &&
        task.dueAt < endUtc;
      const isCompletedOnTargetDate =
        task.completedAt !== null &&
        task.completedAt >= startUtc &&
        task.completedAt < endUtc;
      const isNoDueDate = task.dueAt === null;
      const isOverdue =
        !isDone && task.dueAt !== null && task.dueAt < overdueCutoff;

      if (isOverdue) {
        overdueCount += 1;
      }

      if (isDone && (isDueOnTargetDate || isCompletedOnTargetDate)) {
        completedCount += 1;
        candidateTodayTasks.push(task);
      } else if (!isDone && (isDueOnTargetDate || isNoDueDate)) {
        pendingCount += 1;
        candidateTodayTasks.push(task);
      } else if (isOverdue) {
        candidateTodayTasks.push(task);
      }
    }

    const totalCount = completedCount + pendingCount;

    candidateTodayTasks.sort((a, b) => {
      const aDone = a.status === TaskStatus.DONE ? 1 : 0;
      const bDone = b.status === TaskStatus.DONE ? 1 : 0;
      if (aDone !== bDone) return aDone - bDone;

      if (a.dueAt !== null && b.dueAt !== null) {
        const diff = a.dueAt.getTime() - b.dueAt.getTime();
        if (diff !== 0) return diff;
      } else if (a.dueAt !== null && b.dueAt === null) {
        return -1;
      } else if (a.dueAt === null && b.dueAt !== null) {
        return 1;
      }

      const pDiff =
        DashboardService.PRIORITY_WEIGHT[b.priority] -
        DashboardService.PRIORITY_WEIGHT[a.priority];
      if (pDiff !== 0) return pDiff;

      return b.createdAt.getTime() - a.createdAt.getTime();
    });

    const todayTasks = candidateTodayTasks.slice(0, 5);

    const scheduledHabits = activeHabits.filter((h) =>
      h.activeDays.includes(isoWeekday),
    );

    const todayHabits: HabitWithMetrics[] = scheduledHabits.map((habit) => {
      const completedSet = new Set<string>(
        habit.logs
          .map((l) => HabitsService.toDateOnlyString(l.logDate))
          .filter((d) => d <= targetDate),
      );
      const currentStreak = HabitsService.calculateStreak(
        habit.activeDays,
        completedSet,
        targetDate,
      );
      const completedToday = completedSet.has(targetDate);
      const weeklyLogs = HabitsService.buildWeeklyLogs(
        habit.activeDays,
        completedSet,
        targetDate,
      );
      const { logs: _logs, ...rest } = habit;
      return {
        ...rest,
        currentStreak,
        completedToday,
        weeklyLogs,
      };
    });

    const habitsCompletedCount = todayHabits.filter(
      (h) => h.completedToday,
    ).length;

    return {
      date: targetDate,
      timezone: user.timezone,
      tasks: {
        total: totalCount,
        completed: completedCount,
        pending: pendingCount,
        overdue: overdueCount,
      },
      habits: {
        scheduled: todayHabits.length,
        completed: habitsCompletedCount,
      },
      upcomingEvents,
      todayTasks,
      todayHabits,
    };
  }
}
