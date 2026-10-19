import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Priority, ReminderStatus, TaskStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { TasksService } from './tasks.service';

describe('TasksService', () => {
  let service: TasksService;
  let taskDelegate: {
    findMany: jest.Mock;
    count: jest.Mock;
    create: jest.Mock;
    findFirst: jest.Mock;
    update: jest.Mock;
    deleteMany: jest.Mock;
  };
  let reminderDelegate: {
    updateMany: jest.Mock;
  };
  let prisma: {
    task: typeof taskDelegate;
    reminder: typeof reminderDelegate;
    $transaction: jest.Mock;
  };

  const currentUser = {
    id: 'user-uuid-1',
    email: 'rayhan@example.com',
    timezone: 'Asia/Jakarta',
  };

  const baseTask = {
    id: 'task-uuid-1',
    userId: currentUser.id,
    title: 'Menyelesaikan proyek Flutter',
    description: 'Implementasi task manager',
    status: TaskStatus.TODO,
    priority: Priority.HIGH,
    dueAt: new Date('2026-10-20T12:00:00.000Z'),
    completedAt: null,
    createdAt: new Date('2026-10-18T12:00:00.000Z'),
    updatedAt: new Date('2026-10-18T12:00:00.000Z'),
  };

  beforeEach(async () => {
    taskDelegate = {
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
    };
    reminderDelegate = {
      updateMany: jest.fn(),
    };
    prisma = {
      task: taskDelegate,
      reminder: reminderDelegate,
      $transaction: jest.fn((cb: (tx: unknown) => Promise<unknown>) =>
        cb(prisma),
      ),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [
        TasksService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = moduleRef.get(TasksService);
  });

  describe('create', () => {
    it('membuat task baru dengan default status TODO dan completedAt null', async () => {
      taskDelegate.create.mockResolvedValue(baseTask);

      const created = await service.create(currentUser.id, {
        title: '  Menyelesaikan proyek Flutter  ',
        description: 'Implementasi task manager',
        priority: Priority.HIGH,
        dueAt: '2026-10-20T12:00:00.000Z',
      });

      expect(taskDelegate.create).toHaveBeenCalledWith({
        data: {
          userId: currentUser.id,
          title: 'Menyelesaikan proyek Flutter',
          description: 'Implementasi task manager',
          status: TaskStatus.TODO,
          priority: Priority.HIGH,
          dueAt: new Date('2026-10-20T12:00:00.000Z'),
          completedAt: null,
        },
      });
      expect(created.id).toBe(baseTask.id);
    });

    it('mengisi completedAt jika task langsung dibuat dengan status DONE', async () => {
      taskDelegate.create.mockResolvedValue({
        ...baseTask,
        status: TaskStatus.DONE,
        completedAt: new Date(),
      });

      await service.create(currentUser.id, {
        title: 'Task selesai',
        status: TaskStatus.DONE,
      });

      expect(taskDelegate.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          status: TaskStatus.DONE,
          completedAt: expect.any(Date),
        }),
      });
    });
  });

  describe('list', () => {
    it('memfilter berdasarkan status, priority, search, dan rentang tanggal timezone user', async () => {
      taskDelegate.findMany.mockResolvedValue([baseTask]);
      taskDelegate.count.mockResolvedValue(1);

      const result = await service.list(currentUser, {
        status: TaskStatus.TODO,
        priority: Priority.HIGH,
        from: '2026-10-18',
        to: '2026-10-18',
        search: 'Flutter',
        page: 1,
        limit: 20,
      });

      expect(taskDelegate.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            userId: currentUser.id,
            status: TaskStatus.TODO,
            priority: Priority.HIGH,
            dueAt: {
              gte: new Date('2026-10-17T17:00:00.000Z'),
              lt: new Date('2026-10-18T17:00:00.000Z'),
            },
            OR: [
              { title: { contains: 'Flutter', mode: 'insensitive' } },
              { description: { contains: 'Flutter', mode: 'insensitive' } },
            ],
          },
          skip: 0,
          take: 20,
        }),
      );
      expect(result.meta).toEqual({
        page: 1,
        limit: 20,
        totalItems: 1,
        totalPages: 1,
      });
    });
  });

  describe('update — completedAt lifecycle & reminder auto-cancellation', () => {
    it('mengisi completedAt dan membatalkan reminder SCHEDULED saat status berubah ke DONE', async () => {
      taskDelegate.findFirst.mockResolvedValue(baseTask);
      taskDelegate.update.mockImplementation(
        ({ data }: { data: Record<string, unknown> }) =>
          Promise.resolve({ ...baseTask, ...data }),
      );

      const updated = await service.update(currentUser.id, baseTask.id, {
        status: TaskStatus.DONE,
      });

      expect(updated.status).toBe(TaskStatus.DONE);
      expect(updated.completedAt).toBeInstanceOf(Date);
      expect(reminderDelegate.updateMany).toHaveBeenCalledWith({
        where: {
          taskId: baseTask.id,
          userId: currentUser.id,
          status: ReminderStatus.SCHEDULED,
        },
        data: {
          status: ReminderStatus.CANCELLED,
        },
      });
    });

    it('mengosongkan completedAt (null) saat task dibuka kembali dari DONE ke TODO/IN_PROGRESS', async () => {
      taskDelegate.findFirst.mockResolvedValue({
        ...baseTask,
        status: TaskStatus.DONE,
        completedAt: new Date('2026-10-19T01:00:00.000Z'),
      });
      taskDelegate.update.mockImplementation(
        ({ data }: { data: Record<string, unknown> }) =>
          Promise.resolve({ ...baseTask, ...data }),
      );

      const reopened = await service.update(currentUser.id, baseTask.id, {
        status: TaskStatus.IN_PROGRESS,
      });

      expect(reopened.status).toBe(TaskStatus.IN_PROGRESS);
      expect(reopened.completedAt).toBeNull();
      expect(reminderDelegate.updateMany).not.toHaveBeenCalled();
    });

    it('menolak update pada task yang bukan milik user (Zero IDOR -> 404)', async () => {
      taskDelegate.findFirst.mockResolvedValue(null);

      await expect(
        service.update(currentUser.id, 'other-user-task-uuid', {
          title: 'Hack',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('findOne & remove (Zero IDOR)', () => {
    it('findOne melempar 404 jika task tidak ditemukan atau milik user lain', async () => {
      taskDelegate.findFirst.mockResolvedValue(null);

      await expect(
        service.findOne(currentUser.id, 'missing-uuid'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('remove menghapus task milik sendiri dan melempar 404 jika milik user lain', async () => {
      taskDelegate.deleteMany.mockResolvedValueOnce({ count: 1 });
      const res = await service.remove(currentUser.id, baseTask.id);
      expect(res).toEqual({ id: baseTask.id, deleted: true });

      taskDelegate.deleteMany.mockResolvedValueOnce({ count: 0 });
      await expect(
        service.remove(currentUser.id, 'other-task-uuid'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
