import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Priority, TaskStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CalendarService } from './calendar.service';

describe('CalendarService', () => {
  let service: CalendarService;
  let calendarEventDelegate: {
    findMany: jest.Mock;
    create: jest.Mock;
    findFirst: jest.Mock;
    update: jest.Mock;
    deleteMany: jest.Mock;
  };
  let taskDelegate: {
    findMany: jest.Mock;
  };
  let prisma: {
    calendarEvent: typeof calendarEventDelegate;
    task: typeof taskDelegate;
  };

  const currentUser = {
    id: 'user-uuid-1',
    email: 'rayhan@example.com',
    timezone: 'Asia/Jakarta',
  };

  beforeEach(async () => {
    calendarEventDelegate = {
      findMany: jest.fn(),
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
    };
    taskDelegate = {
      findMany: jest.fn(),
    };
    prisma = {
      calendarEvent: calendarEventDelegate,
      task: taskDelegate,
    };

    const moduleRef = await Test.createTestingModule({
      providers: [
        CalendarService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = moduleRef.get(CalendarService);
  });

  describe('create & update validation', () => {
    it('menolak endsAt <= startsAt dengan 400 INVALID_TIME_RANGE', async () => {
      await expect(
        service.create(currentUser.id, {
          title: 'Kuliah Sistem Operasi',
          startsAt: '2026-10-18T03:00:00.000Z',
          endsAt: '2026-10-18T01:00:00.000Z',
        }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({
          code: 'INVALID_TIME_RANGE',
        }),
      });

      await expect(
        service.create(currentUser.id, {
          title: 'Kuliah Sistem Operasi',
          startsAt: '2026-10-18T01:00:00.000Z',
          endsAt: '2026-10-18T01:00:00.000Z',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('membuat event valid saat endsAt > startsAt', async () => {
      const createdRecord = {
        id: 'event-1',
        userId: currentUser.id,
        title: 'Kuliah Sistem Operasi',
        description: null,
        location: 'Gedung B R.204',
        startsAt: new Date('2026-10-18T01:00:00.000Z'),
        endsAt: new Date('2026-10-18T03:00:00.000Z'),
        createdAt: new Date('2026-10-18T00:00:00.000Z'),
        updatedAt: new Date('2026-10-18T00:00:00.000Z'),
      };
      calendarEventDelegate.create.mockResolvedValue(createdRecord);

      const res = await service.create(currentUser.id, {
        title: '  Kuliah Sistem Operasi  ',
        location: 'Gedung B R.204',
        startsAt: '2026-10-18T01:00:00.000Z',
        endsAt: '2026-10-18T03:00:00.000Z',
      });

      expect(res.title).toBe('Kuliah Sistem Operasi');
      expect(calendarEventDelegate.create).toHaveBeenCalledTimes(1);
    });

    it('menolak akses event milik user lain dengan 404 NotFoundException', async () => {
      calendarEventDelegate.findFirst.mockResolvedValue(null);
      await expect(
        service.findOne(currentUser.id, 'other-event-id'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('listAgenda', () => {
    it('mengembalikan events (type=EVENT) dan tasks (type=TASK) dalam interval [startUtc, endUtc)', async () => {
      calendarEventDelegate.findMany.mockResolvedValue([
        {
          id: 'ev-1',
          userId: currentUser.id,
          title: 'Belajar pemrograman',
          description: null,
          location: 'Rumah',
          startsAt: new Date('2026-10-18T01:00:00.000Z'),
          endsAt: new Date('2026-10-18T03:00:00.000Z'),
          createdAt: new Date('2026-10-18T00:00:00.000Z'),
          updatedAt: new Date('2026-10-18T00:00:00.000Z'),
        },
      ]);
      taskDelegate.findMany.mockResolvedValue([
        {
          id: 'tk-1',
          userId: currentUser.id,
          title: 'Menyelesaikan proyek Flutter',
          description: null,
          status: TaskStatus.TODO,
          priority: Priority.HIGH,
          dueAt: new Date('2026-10-18T05:00:00.000Z'),
          completedAt: null,
          createdAt: new Date('2026-10-18T00:00:00.000Z'),
          updatedAt: new Date('2026-10-18T00:00:00.000Z'),
        },
      ]);

      const agenda = await service.listAgenda(currentUser, {
        from: '2026-10-18',
        to: '2026-10-18',
      });

      expect(agenda.from).toBe('2026-10-18');
      expect(agenda.to).toBe('2026-10-18');
      expect(agenda.events).toHaveLength(1);
      expect(agenda.events[0].type).toBe('EVENT');
      expect(agenda.tasks).toHaveLength(1);
      expect(agenda.tasks[0].type).toBe('TASK');
    });
  });
});
