import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { HabitsService } from './habits.service';

describe('HabitsService', () => {
  let service: HabitsService;
  let habitDelegate: {
    findMany: jest.Mock;
    create: jest.Mock;
    findFirst: jest.Mock;
    update: jest.Mock;
    deleteMany: jest.Mock;
  };
  let habitLogDelegate: {
    findUnique: jest.Mock;
    upsert: jest.Mock;
    deleteMany: jest.Mock;
    findMany: jest.Mock;
  };
  let prisma: {
    habit: typeof habitDelegate;
    habitLog: typeof habitLogDelegate;
  };

  const currentUser = {
    id: 'user-uuid-1',
    email: 'rayhan@example.com',
    timezone: 'Asia/Jakarta',
  };

  // 2026-10-16 08:00 WIB = 2026-10-16T01:00:00.000Z (Friday, isoWeekday = 5)
  const fridayMorningNow = new Date('2026-10-16T01:00:00.000Z');

  const baseHabit = {
    id: 'habit-uuid-1',
    userId: currentUser.id,
    name: 'Membaca',
    description: 'Membaca selama 20 menit',
    isActive: true,
    activeDays: [1, 3, 5],
    createdAt: new Date('2026-10-10T01:00:00.000Z'),
    updatedAt: new Date('2026-10-10T01:00:00.000Z'),
  };

  beforeEach(async () => {
    habitDelegate = {
      findMany: jest.fn(),
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
    };
    habitLogDelegate = {
      findUnique: jest.fn(),
      upsert: jest.fn(),
      deleteMany: jest.fn(),
      findMany: jest.fn(),
    };
    prisma = {
      habit: habitDelegate,
      habitLog: habitLogDelegate,
    };

    const moduleRef = await Test.createTestingModule({
      providers: [
        HabitsService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = moduleRef.get(HabitsService);
  });

  describe('normalizeActiveDays', () => {
    it('mengurutkan activeDays secara kanonik menaik', () => {
      expect(HabitsService.normalizeActiveDays([5, 1, 3])).toEqual([1, 3, 5]);
      expect(HabitsService.normalizeActiveDays(undefined)).toEqual([
        1, 2, 3, 4, 5, 6, 7,
      ]);
    });

    it('menolak [], [0], [8], dan duplikat [1, 1, 3] dengan 400 VALIDATION_ERROR', () => {
      const invalidCases: number[][] = [[], [0], [8], [1, 1, 3]];

      for (const invalid of invalidCases) {
        expect(() => HabitsService.normalizeActiveDays(invalid)).toThrow(
          BadRequestException,
        );
      }
    });
  });

  describe('calculateStreak (§3.1 deterministic specification)', () => {
    it('(a) jadwal Sen-Rab-Jum [1,3,5], selesai Sen & Rab -> hari Kamis (hari non-aktif) streak = 2', () => {
      // 2026-10-12 = Mon(1), 2026-10-14 = Wed(3), 2026-10-15 = Thu(4)
      const streak = HabitsService.calculateStreak(
        [1, 3, 5],
        ['2026-10-12', '2026-10-14'],
        '2026-10-15',
      );
      expect(streak).toBe(2);
    });

    it('(b) jadwal Sen-Rab-Jum [1,3,5], selesai Sen & Rab -> Jumat pagi sebelum check-in tetap 2, setelah check-in jadi 3', () => {
      // 2026-10-16 = Fri(5)
      const beforeCheckIn = HabitsService.calculateStreak(
        [1, 3, 5],
        ['2026-10-12', '2026-10-14'],
        '2026-10-16',
      );
      expect(beforeCheckIn).toBe(2);

      const afterCheckIn = HabitsService.calculateStreak(
        [1, 3, 5],
        ['2026-10-12', '2026-10-14', '2026-10-16'],
        '2026-10-16',
      );
      expect(afterCheckIn).toBe(3);
    });

    it('(c) habit baru dibuat hari ini: sebelum check-in = 0, setelah check-in = 1', () => {
      expect(
        HabitsService.calculateStreak([1, 2, 3, 4, 5, 6, 7], [], '2026-10-16'),
      ).toBe(0);

      expect(
        HabitsService.calculateStreak(
          [1, 2, 3, 4, 5, 6, 7],
          ['2026-10-16'],
          '2026-10-16',
        ),
      ).toBe(1);
    });

    it('memutus streak jika ada scheduled day sebelumnya yang terlewat', () => {
      // Jadwal [1,3,5]: selesai Senin (2026-10-12), Rabu (2026-10-14) terlewat -> pada Kamis (2026-10-15) streak = 0
      const streak = HabitsService.calculateStreak(
        [1, 3, 5],
        ['2026-10-12'],
        '2026-10-15',
      );
      expect(streak).toBe(0);
    });

    it('mengabaikan log masa depan (logDate > todayLocal) dalam perhitungan streak', () => {
      const streak = HabitsService.calculateStreak(
        [1, 2, 3, 4, 5, 6, 7],
        ['2026-10-16', '2026-10-17', '2026-10-18'],
        '2026-10-16',
      );
      expect(streak).toBe(1);
    });
  });

  describe('checkIn (PUT /habits/:id/logs/:date)', () => {
    it('menolak log masa depan (logDate > todayLocal) dengan 400 FUTURE_HABIT_LOG_NOT_ALLOWED', async () => {
      await expect(
        service.checkIn(
          currentUser,
          baseHabit.id,
          '2026-10-17',
          { completed: true },
          fridayMorningNow,
        ),
      ).rejects.toMatchObject({
        response: expect.objectContaining({
          code: 'FUTURE_HABIT_LOG_NOT_ALLOWED',
        }),
      });
    });

    it('mengizinkan backfill hingga H-7 dan menolak H-8 dengan 400 VALIDATION_ERROR', async () => {
      // Today is 2026-10-16 -> H-7 is 2026-10-09 (allowed), H-8 is 2026-10-08 (rejected)
      await expect(
        service.checkIn(
          currentUser,
          baseHabit.id,
          '2026-10-08',
          { completed: true },
          fridayMorningNow,
        ),
      ).rejects.toThrow(BadRequestException);

      habitDelegate.findFirst.mockResolvedValue(baseHabit);
      habitLogDelegate.findUnique.mockResolvedValue(null);
      habitLogDelegate.upsert.mockResolvedValue({
        id: 'log-1',
        habitId: baseHabit.id,
        logDate: new Date('2026-10-09T00:00:00.000Z'),
        completedAt: fridayMorningNow,
        createdAt: fridayMorningNow,
      });
      habitLogDelegate.findMany.mockResolvedValue([
        {
          id: 'log-1',
          habitId: baseHabit.id,
          logDate: new Date('2026-10-09T00:00:00.000Z'),
          completedAt: fridayMorningNow,
          createdAt: fridayMorningNow,
        },
      ]);

      const h7Result = await service.checkIn(
        currentUser,
        baseHabit.id,
        '2026-10-09',
        { completed: true },
        fridayMorningNow,
      );
      expect(h7Result.completed).toBe(true);
      expect(h7Result.logDate).toBe('2026-10-09');
    });

    it('melakukan upsert saat completed=true dan deleteMany saat completed=false secara idempotent', async () => {
      habitDelegate.findFirst.mockResolvedValue(baseHabit);
      habitLogDelegate.findUnique.mockResolvedValue(null);
      habitLogDelegate.upsert.mockResolvedValue({
        id: 'log-today',
        habitId: baseHabit.id,
        logDate: new Date('2026-10-16T00:00:00.000Z'),
        completedAt: fridayMorningNow,
        createdAt: fridayMorningNow,
      });
      habitLogDelegate.findMany.mockResolvedValue([
        {
          id: 'log-today',
          habitId: baseHabit.id,
          logDate: new Date('2026-10-16T00:00:00.000Z'),
          completedAt: fridayMorningNow,
          createdAt: fridayMorningNow,
        },
      ]);

      const checked = await service.checkIn(
        currentUser,
        baseHabit.id,
        '2026-10-16',
        { completed: true },
        fridayMorningNow,
      );
      expect(checked.completed).toBe(true);
      expect(checked.currentStreak).toBe(1);
      expect(habitLogDelegate.upsert).toHaveBeenCalledTimes(1);

      habitLogDelegate.deleteMany.mockResolvedValue({ count: 1 });
      habitLogDelegate.findMany.mockResolvedValue([]);

      const unchecked = await service.checkIn(
        currentUser,
        baseHabit.id,
        '2026-10-16',
        { completed: false },
        fridayMorningNow,
      );
      expect(unchecked.completed).toBe(false);
      expect(unchecked.completedAt).toBeNull();
      expect(unchecked.currentStreak).toBe(0);
      expect(habitLogDelegate.deleteMany).toHaveBeenCalledWith({
        where: {
          habitId: baseHabit.id,
          logDate: new Date('2026-10-16T00:00:00.000Z'),
        },
      });
    });

    it('menolak check-in pada habit milik user lain dengan 404 NotFoundException', async () => {
      habitDelegate.findFirst.mockResolvedValue(null);

      await expect(
        service.checkIn(
          currentUser,
          'other-user-habit-id',
          '2026-10-16',
          { completed: true },
          fridayMorningNow,
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
