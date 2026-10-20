import { Test } from '@nestjs/testing';
import { Priority, TaskStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DashboardService } from './dashboard.service';

describe('DashboardService', () => {
  let service: DashboardService;
  let taskDelegate: { findMany: jest.Mock };
  let calendarEventDelegate: { findMany: jest.Mock };
  let habitDelegate: { findMany: jest.Mock };

  const currentUser = {
    id: 'user-uuid-1',
    email: 'rayhan@example.com',
    timezone: 'Asia/Jakarta',
  };

  // 2026-10-18 (Sunday, isoWeekday = 7) 10:00 WIB = 2026-10-18T03:00:00.000Z
  // Day interval for 2026-10-18 in Asia/Jakarta:
  // [2026-10-17T17:00:00.000Z, 2026-10-18T17:00:00.000Z)
  const nowUtc = new Date('2026-10-18T03:00:00.000Z');

  beforeEach(async () => {
    taskDelegate = { findMany: jest.fn() };
    calendarEventDelegate = { findMany: jest.fn() };
    habitDelegate = { findMany: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        DashboardService,
        {
          provide: PrismaService,
          useValue: {
            task: taskDelegate,
            calendarEvent: calendarEventDelegate,
            habit: habitDelegate,
          },
        },
      ],
    }).compile();

    service = moduleRef.get(DashboardService);
  });

  it('menghitung metrik tasks (total/completed/pending/overdue) dan habits (scheduled/completed) sesuai FR-DASH-02 & FR-DASH-03', async () => {
    taskDelegate.findMany.mockResolvedValue([
      // 1. Due today & DONE -> completed (+1), total (+1)
      {
        id: 't-1',
        userId: currentUser.id,
        title: 'Task Done Today',
        description: null,
        status: TaskStatus.DONE,
        priority: Priority.HIGH,
        dueAt: new Date('2026-10-18T02:00:00.000Z'),
        completedAt: new Date('2026-10-18T01:30:00.000Z'),
        createdAt: new Date('2026-10-17T10:00:00.000Z'),
        updatedAt: new Date('2026-10-18T01:30:00.000Z'),
      },
      // 2. Due today later & TODO -> pending (+1), total (+1)
      {
        id: 't-2',
        userId: currentUser.id,
        title: 'Task Pending Today',
        description: null,
        status: TaskStatus.TODO,
        priority: Priority.MEDIUM,
        dueAt: new Date('2026-10-18T08:00:00.000Z'),
        completedAt: null,
        createdAt: new Date('2026-10-17T10:00:00.000Z'),
        updatedAt: new Date('2026-10-17T10:00:00.000Z'),
      },
      // 3. No dueAt & IN_PROGRESS -> pending (+1), total (+1), never overdue (§10 #1)
      {
        id: 't-3',
        userId: currentUser.id,
        title: 'Backlog Task Tanpa Deadline',
        description: null,
        status: TaskStatus.IN_PROGRESS,
        priority: Priority.HIGH,
        dueAt: null,
        completedAt: null,
        createdAt: new Date('2026-10-17T11:00:00.000Z'),
        updatedAt: new Date('2026-10-17T11:00:00.000Z'),
      },
      // 4. Due yesterday & TODO -> overdue (+1)
      {
        id: 't-4',
        userId: currentUser.id,
        title: 'Overdue Task Kemarin',
        description: null,
        status: TaskStatus.TODO,
        priority: Priority.HIGH,
        dueAt: new Date('2026-10-16T12:00:00.000Z'),
        completedAt: null,
        createdAt: new Date('2026-10-15T10:00:00.000Z'),
        updatedAt: new Date('2026-10-15T10:00:00.000Z'),
      },
    ]);

    calendarEventDelegate.findMany.mockResolvedValue([]);

    habitDelegate.findMany.mockResolvedValue([
      // Scheduled on Sunday (7) & completed today
      {
        id: 'h-1',
        userId: currentUser.id,
        name: 'Minum Air',
        description: null,
        isActive: true,
        activeDays: [1, 2, 3, 4, 5, 6, 7],
        createdAt: new Date('2026-10-01T00:00:00.000Z'),
        updatedAt: new Date('2026-10-01T00:00:00.000Z'),
        logs: [
          {
            id: 'hl-1',
            habitId: 'h-1',
            logDate: new Date('2026-10-18T00:00:00.000Z'),
            completedAt: nowUtc,
            createdAt: nowUtc,
          },
        ],
      },
      // Scheduled on Sunday (7) & NOT completed today
      {
        id: 'h-2',
        userId: currentUser.id,
        name: 'Membaca',
        description: null,
        isActive: true,
        activeDays: [7],
        createdAt: new Date('2026-10-01T00:00:00.000Z'),
        updatedAt: new Date('2026-10-01T00:00:00.000Z'),
        logs: [],
      },
      // Not scheduled on Sunday (weekdays only [1..5]) -> excluded from scheduled
      {
        id: 'h-3',
        userId: currentUser.id,
        name: 'Kuliah Pagi',
        description: null,
        isActive: true,
        activeDays: [1, 2, 3, 4, 5],
        createdAt: new Date('2026-10-01T00:00:00.000Z'),
        updatedAt: new Date('2026-10-01T00:00:00.000Z'),
        logs: [],
      },
    ]);

    const result = await service.getToday(
      currentUser,
      { date: '2026-10-18' },
      nowUtc,
    );

    expect(result.date).toBe('2026-10-18');
    expect(result.timezone).toBe('Asia/Jakarta');
    expect(result.tasks).toEqual({
      total: 3,
      completed: 1,
      pending: 2,
      overdue: 1,
    });
    expect(result.habits).toEqual({
      scheduled: 2,
      completed: 1,
    });
    expect(result.todayHabits).toHaveLength(2);
    expect(result.todayTasks.length).toBeLessThanOrEqual(5);
  });
});
