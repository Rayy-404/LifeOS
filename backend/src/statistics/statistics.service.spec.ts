import { Test } from '@nestjs/testing';
import { TaskStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { StatisticsService } from './statistics.service';

describe('StatisticsService', () => {
  let service: StatisticsService;
  let taskDelegate: { findMany: jest.Mock };
  let habitDelegate: { findMany: jest.Mock };

  const currentUser = {
    id: 'user-uuid-1',
    email: 'rayhan@example.com',
    timezone: 'Asia/Jakarta',
  };

  beforeEach(async () => {
    taskDelegate = { findMany: jest.fn() };
    habitDelegate = { findMany: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        StatisticsService,
        {
          provide: PrismaService,
          useValue: {
            task: taskDelegate,
            habit: habitDelegate,
          },
        },
      ],
    }).compile();

    service = moduleRef.get(StatisticsService);
  });

  describe('getOverview', () => {
    it('menghitung total/completed/overdue/completionRate dan konsistensi habit', async () => {
      taskDelegate.findMany.mockResolvedValue([
        {
          status: TaskStatus.DONE,
          dueAt: new Date('2026-10-12T03:00:00.000Z'),
          completedAt: new Date('2026-10-12T04:00:00.000Z'),
        },
        {
          status: TaskStatus.TODO,
          dueAt: new Date('2026-10-13T03:00:00.000Z'),
          completedAt: null,
        },
        {
          status: TaskStatus.IN_PROGRESS,
          dueAt: new Date('2026-10-17T03:00:00.000Z'),
          completedAt: null,
        },
        {
          status: TaskStatus.DONE,
          dueAt: new Date('2026-10-01T03:00:00.000Z'),
          completedAt: new Date('2026-10-15T04:00:00.000Z'),
        },
      ]);

      habitDelegate.findMany.mockResolvedValue([
        {
          id: 'habit-daily',
          activeDays: [1, 2, 3, 4, 5, 6, 7],
          logs: [
            { logDate: new Date('2026-10-12T00:00:00.000Z') },
            { logDate: new Date('2026-10-13T00:00:00.000Z') },
            { logDate: new Date('2026-10-14T00:00:00.000Z') },
          ],
        },
        {
          id: 'habit-mwf',
          activeDays: [1, 3, 5],
          logs: [
            { logDate: new Date('2026-10-12T00:00:00.000Z') },
            { logDate: new Date('2026-10-13T00:00:00.000Z') },
          ],
        },
      ]);

      const result = await service.getOverview(
        currentUser,
        { from: '2026-10-12', to: '2026-10-18' },
        new Date('2026-10-18T03:00:00.000Z'),
      );

      expect(result.tasks).toEqual({
        total: 4,
        completed: 2,
        overdue: 2,
        completionRate: 50,
      });
      expect(result.habits).toEqual({
        totalScheduledInstances: 10,
        totalCompletedInstances: 4,
        consistencyRate: 40,
      });
    });
  });

  describe('getWeekly', () => {
    it('membagi completedAt ke tanggal lokal user dan menghitung habit per hari', async () => {
      taskDelegate.findMany.mockResolvedValue([
        // Monday 08:00 WIB
        { completedAt: new Date('2026-10-12T01:00:00.000Z') },
        // Monday 21:00 WIB
        { completedAt: new Date('2026-10-12T14:00:00.000Z') },
        // Tuesday 00:30 WIB (must not leak into Monday)
        { completedAt: new Date('2026-10-12T17:30:00.000Z') },
      ]);

      habitDelegate.findMany.mockResolvedValue([
        {
          id: 'habit-daily',
          activeDays: [1, 2, 3, 4, 5, 6, 7],
          logs: [
            { logDate: new Date('2026-10-12T00:00:00.000Z') },
            { logDate: new Date('2026-10-13T00:00:00.000Z') },
          ],
        },
        {
          id: 'habit-mwf',
          activeDays: [1, 3, 5],
          logs: [{ logDate: new Date('2026-10-12T00:00:00.000Z') }],
        },
      ]);

      const result = await service.getWeekly(currentUser, {
        weekStart: '2026-10-12',
      });

      expect(result.weekEnd).toBe('2026-10-18');
      expect(result.days).toHaveLength(7);
      expect(result.days[0]).toEqual({
        date: '2026-10-12',
        isoWeekday: 1,
        tasksCompleted: 2,
        habitsScheduled: 2,
        habitsCompleted: 2,
      });
      expect(result.days[1]).toEqual({
        date: '2026-10-13',
        isoWeekday: 2,
        tasksCompleted: 1,
        habitsScheduled: 1,
        habitsCompleted: 1,
      });
      expect(result.days[2]).toEqual({
        date: '2026-10-14',
        isoWeekday: 3,
        tasksCompleted: 0,
        habitsScheduled: 2,
        habitsCompleted: 0,
      });
      expect(result.days[6].date).toBe('2026-10-18');
    });
  });
});
