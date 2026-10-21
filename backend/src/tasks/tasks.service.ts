import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  Priority,
  Prisma,
  Reminder,
  ReminderStatus,
  Task,
  TaskStatus,
} from '@prisma/client';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';
import { DateRangeHelper } from '../common/utils/date-range.helper';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { ListTasksQueryDto } from './dto/list-tasks-query.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

export interface PaginationMeta {
  page: number;
  limit: number;
  totalItems: number;
  totalPages: number;
}

export interface PaginatedTasksResult {
  data: Task[];
  meta: PaginationMeta;
}

export type TaskWithReminders = Task & { reminders: Reminder[] };

/**
 * Task Management service (`03-technical-spec.md` Sections 3 & 4.2):
 * Enforces Zero IDOR (`userId` ownership on every query), `completedAt`
 * lifecycle transitions, automatic reminder cancellation on `DONE`, and
 * timezone-aware `[startUtc, endUtc)` filtering.
 */
@Injectable()
export class TasksService {
  private static readonly DATE_ONLY_REGEX = /^\d{4}-\d{2}-\d{2}$/;

  constructor(private readonly prisma: PrismaService) {}

  async list(
    user: AuthenticatedUser,
    query: ListTasksQueryDto,
  ): Promise<PaginatedTasksResult> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: Prisma.TaskWhereInput = {
      userId: user.id,
    };

    if (query.status) {
      where.status = query.status;
    }
    if (query.priority) {
      where.priority = query.priority;
    }

    if (query.from && query.to) {
      const { startUtc, endUtc } = DateRangeHelper.getRangeUtcInterval(
        query.from,
        query.to,
        user.timezone,
      );
      where.dueAt = { gte: startUtc, lt: endUtc };
    } else if (query.from) {
      const startUtc = TasksService.resolveBoundaryUtc(
        query.from,
        user.timezone,
        'start',
      );
      where.dueAt = { gte: startUtc };
    } else if (query.to) {
      const endUtc = TasksService.resolveBoundaryUtc(
        query.to,
        user.timezone,
        'end',
      );
      where.dueAt = { lt: endUtc };
    }

    if (query.search) {
      where.OR = [
        { title: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [items, totalItems] = await Promise.all([
      this.prisma.task.findMany({
        where,
        skip,
        take: limit,
        include: {
          reminders: {
            select: { id: true, status: true },
          },
        },
        orderBy: [
          { dueAt: { sort: 'asc', nulls: 'last' } },
          { priority: 'desc' },
          { createdAt: 'desc' },
        ],
      }),
      this.prisma.task.count({ where }),
    ]);

    const totalPages = totalItems === 0 ? 0 : Math.ceil(totalItems / limit);

    return {
      data: items,
      meta: {
        page,
        limit,
        totalItems,
        totalPages,
      },
    };
  }

  async create(userId: string, dto: CreateTaskDto): Promise<Task> {
    const status = dto.status ?? TaskStatus.TODO;
    const completedAt = status === TaskStatus.DONE ? new Date() : null;

    return this.prisma.task.create({
      data: {
        userId,
        title: dto.title.trim(),
        description: dto.description ?? null,
        status,
        priority: dto.priority ?? Priority.MEDIUM,
        dueAt: dto.dueAt ? new Date(dto.dueAt) : null,
        completedAt,
      },
    });
  }

  async findOne(userId: string, taskId: string): Promise<TaskWithReminders> {
    const task = await this.prisma.task.findFirst({
      where: { id: taskId, userId },
      include: {
        reminders: {
          orderBy: { remindAt: 'asc' },
        },
      },
    });

    if (!task) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Task not found',
      });
    }

    return task;
  }

  async update(
    userId: string,
    taskId: string,
    dto: UpdateTaskDto,
  ): Promise<Task> {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.task.findFirst({
        where: { id: taskId, userId },
      });

      if (!existing) {
        throw new NotFoundException({
          code: 'RESOURCE_NOT_FOUND',
          message: 'Task not found',
        });
      }

      const data: Prisma.TaskUpdateInput = {};

      if (dto.title !== undefined) {
        data.title = dto.title.trim();
      }
      if (dto.description !== undefined) {
        data.description = dto.description;
      }
      if (dto.priority !== undefined) {
        data.priority = dto.priority;
      }
      if (dto.dueAt !== undefined) {
        data.dueAt = dto.dueAt ? new Date(dto.dueAt) : null;
      }

      if (dto.status !== undefined) {
        data.status = dto.status;
        if (
          dto.status === TaskStatus.DONE &&
          existing.status !== TaskStatus.DONE
        ) {
          data.completedAt = new Date();
        } else if (
          dto.status !== TaskStatus.DONE &&
          existing.status === TaskStatus.DONE
        ) {
          data.completedAt = null;
        }

        if (dto.status === TaskStatus.DONE) {
          await tx.reminder.updateMany({
            where: {
              taskId,
              userId,
              status: ReminderStatus.SCHEDULED,
            },
            data: {
              status: ReminderStatus.CANCELLED,
            },
          });
        }
      }

      return tx.task.update({
        where: { id: taskId },
        data,
      });
    });
  }

  async remove(
    userId: string,
    taskId: string,
  ): Promise<{ id: string; deleted: boolean }> {
    const deleted = await this.prisma.task.deleteMany({
      where: { id: taskId, userId },
    });

    if (deleted.count === 0) {
      throw new NotFoundException({
        code: 'RESOURCE_NOT_FOUND',
        message: 'Task not found',
      });
    }

    return { id: taskId, deleted: true };
  }

  private static resolveBoundaryUtc(
    raw: string,
    timezone: string,
    edge: 'start' | 'end',
  ): Date {
    if (this.DATE_ONLY_REGEX.test(raw)) {
      const interval = DateRangeHelper.getDayUtcInterval(raw, timezone);
      return edge === 'start' ? interval.startUtc : interval.endUtc;
    }

    const parsed = new Date(raw);
    if (isNaN(parsed.getTime())) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: `Invalid date/time parameter "${raw}".`,
      });
    }
    return parsed;
  }
}
