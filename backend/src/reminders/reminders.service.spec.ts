import { Test } from '@nestjs/testing';
import { ReminderChannel, ReminderStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RemindersService } from './reminders.service';

describe('RemindersService', () => {
  let service: RemindersService;
  let reminderDelegate: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
    deleteMany: jest.Mock;
  };
  let taskDelegate: { findFirst: jest.Mock };
  let eventDelegate: { findFirst: jest.Mock };

  const currentUser = {
    id: 'user-uuid-1',
    email: 'rayhan@example.com',
    timezone: 'Asia/Jakarta',
  };

  const futureIso = new Date(Date.now() + 60 * 60 * 1000).toISOString();
  const pastIso = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const taskId = '11111111-1111-4111-8111-111111111111';
  const eventId = '22222222-2222-4222-8222-222222222222';
  const reminderId = '33333333-3333-4333-8333-333333333333';

  beforeEach(async () => {
    reminderDelegate = {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
    };
    taskDelegate = { findFirst: jest.fn() };
    eventDelegate = { findFirst: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        RemindersService,
        {
          provide: PrismaService,
          useValue: {
            reminder: reminderDelegate,
            task: taskDelegate,
            calendarEvent: eventDelegate,
          },
        },
      ],
    }).compile();

    service = moduleRef.get(RemindersService);
  });

  describe('XOR target invariant (FR-REM-01)', () => {
    it('menolak reminder tanpa target atau dengan dua target', async () => {
      await expect(
        service.create(currentUser, {
          remindAt: futureIso,
        }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({
          code: 'REMINDER_TARGET_XOR_VIOLATION',
        }),
      });

      await expect(
        service.create(currentUser, {
          taskId,
          eventId,
          remindAt: futureIso,
        }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({
          code: 'REMINDER_TARGET_XOR_VIOLATION',
        }),
      });

      expect(reminderDelegate.create).not.toHaveBeenCalled();
    });
  });

  describe('Zero IDOR target ownership (FR-REM-02 / OD-01)', () => {
    it('menolak taskId milik user lain dengan 404 tanpa membocorkan eksistensi', async () => {
      taskDelegate.findFirst.mockResolvedValue(null);

      await expect(
        service.create(currentUser, {
          taskId,
          remindAt: futureIso,
        }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'RESOURCE_NOT_FOUND' }),
      });

      expect(taskDelegate.findFirst).toHaveBeenCalledWith({
        where: { id: taskId, userId: currentUser.id },
        select: { id: true },
      });
      expect(reminderDelegate.create).not.toHaveBeenCalled();
    });

    it('menolak eventId milik user lain dengan 404', async () => {
      eventDelegate.findFirst.mockResolvedValue(null);

      await expect(
        service.create(currentUser, {
          eventId,
          remindAt: futureIso,
        }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'RESOURCE_NOT_FOUND' }),
      });
    });
  });

  describe('create', () => {
    it('menyimpan reminder sebagai SCHEDULED dengan channel default LOCAL', async () => {
      taskDelegate.findFirst.mockResolvedValue({ id: taskId });
      reminderDelegate.create.mockResolvedValue({ id: reminderId });

      await service.create(currentUser, {
        taskId,
        remindAt: futureIso,
      });

      expect(reminderDelegate.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            userId: currentUser.id,
            taskId,
            eventId: null,
            channel: ReminderChannel.LOCAL,
            status: ReminderStatus.SCHEDULED,
          }),
        }),
      );
    });

    it('menolak remindAt di masa lalu dengan 400 INVALID_REMINDER_TIME', async () => {
      await expect(
        service.create(currentUser, {
          taskId,
          remindAt: pastIso,
        }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'INVALID_REMINDER_TIME' }),
      });

      expect(taskDelegate.findFirst).not.toHaveBeenCalled();
    });
  });

  describe('update', () => {
    it('mengubah remindAt ke masa depan dan otomatis mengembalikan status SCHEDULED', async () => {
      reminderDelegate.findFirst.mockResolvedValue({
        id: reminderId,
        userId: currentUser.id,
        status: ReminderStatus.CANCELLED,
      });
      reminderDelegate.update.mockResolvedValue({ id: reminderId });

      await service.update(currentUser, reminderId, {
        remindAt: futureIso,
      });

      expect(reminderDelegate.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: reminderId },
          data: expect.objectContaining({
            remindAt: new Date(futureIso),
            status: ReminderStatus.SCHEDULED,
          }),
        }),
      );
    });

    it('mengizinkan klien menandai status SENT/FAILED/CANCELLED', async () => {
      reminderDelegate.findFirst.mockResolvedValue({
        id: reminderId,
        userId: currentUser.id,
      });
      reminderDelegate.update.mockResolvedValue({ id: reminderId });

      await service.update(currentUser, reminderId, {
        status: ReminderStatus.SENT,
      });

      expect(reminderDelegate.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { status: ReminderStatus.SENT },
        }),
      );
    });

    it('mengembalikan 404 untuk reminder milik user lain', async () => {
      reminderDelegate.findFirst.mockResolvedValue(null);

      await expect(
        service.update(currentUser, reminderId, {
          status: ReminderStatus.FAILED,
        }),
      ).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'RESOURCE_NOT_FOUND' }),
      });
    });
  });

  describe('list & remove', () => {
    it('memfilter status dan mengurutkan remindAt ASC', async () => {
      reminderDelegate.findMany.mockResolvedValue([]);

      await service.list(currentUser, { status: ReminderStatus.SCHEDULED });

      expect(reminderDelegate.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId: currentUser.id, status: ReminderStatus.SCHEDULED },
          orderBy: { remindAt: 'asc' },
        }),
      );
    });

    it('mengembalikan 404 saat reminder yang dihapus tidak ada', async () => {
      reminderDelegate.deleteMany.mockResolvedValue({ count: 0 });

      await expect(
        service.remove(currentUser, reminderId),
      ).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'RESOURCE_NOT_FOUND' }),
      });
    });
  });
});
