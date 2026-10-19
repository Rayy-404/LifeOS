import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';

jest.mock('argon2', () => ({
  hash: jest.fn().mockResolvedValue('$argon2id$mocked-hash'),
  verify: jest.fn().mockResolvedValue(true),
  argon2id: 2,
}));

describe('AuthService', () => {
  let service: AuthService;
  let usersService: {
    findByEmail: jest.Mock;
    findById: jest.Mock;
    create: jest.Mock;
  };
  let refreshTokenDelegate: {
    create: jest.Mock;
    updateMany: jest.Mock;
    findUnique: jest.Mock;
  };
  let userDelegate: { findUniqueOrThrow: jest.Mock };
  let prisma: {
    refreshToken: typeof refreshTokenDelegate;
    user: typeof userDelegate;
    $transaction: jest.Mock;
  };
  let jwtService: { signAsync: jest.Mock };

  const futureDate = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30);

  const userFixture = {
    id: 'user-1',
    email: 'rayhan@example.com',
    passwordHash: '$argon2id$mocked-hash',
    name: 'Rayhan',
    timezone: 'Asia/Jakarta',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    usersService = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      create: jest.fn(),
    };
    refreshTokenDelegate = {
      create: jest.fn(),
      updateMany: jest.fn(),
      findUnique: jest.fn(),
    };
    userDelegate = { findUniqueOrThrow: jest.fn() };
    prisma = {
      refreshToken: refreshTokenDelegate,
      user: userDelegate,
      $transaction: jest.fn(),
    };
    prisma.$transaction.mockImplementation(
      (callback: (tx: unknown) => Promise<unknown>) => callback(prisma),
    );
    jwtService = {
      signAsync: jest.fn().mockResolvedValue('signed.access.token'),
    };

    const configService = {
      get: jest.fn((key: string) => {
        const values: Record<string, string> = {
          JWT_ACCESS_TTL: '15m',
          REFRESH_TOKEN_TTL_DAYS: '30',
        };
        return values[key];
      }),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: usersService },
        { provide: PrismaService, useValue: prisma },
        { provide: JwtService, useValue: jwtService },
        { provide: ConfigService, useValue: configService },
      ],
    }).compile();

    service = moduleRef.get(AuthService);
    (argon2.hash as jest.Mock)
      .mockClear()
      .mockResolvedValue('$argon2id$mocked-hash');
    (argon2.verify as jest.Mock).mockClear().mockResolvedValue(true);
  });

  describe('register', () => {
    it('menormalkan email ke trimmed lowercase sebelum disimpan', async () => {
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue(userFixture);

      const session = await service.register({
        name: '  Rayhan  ',
        email: '  Rayhan@Example.COM ',
        password: 'strong-password',
        timezone: 'Asia/Jakarta',
      });

      expect(usersService.findByEmail).toHaveBeenCalledWith(
        'rayhan@example.com',
      );
      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'rayhan@example.com',
          name: 'Rayhan',
        }),
      );
      expect(argon2.hash).toHaveBeenCalled();
      expect(session.accessToken).toBe('signed.access.token');
      expect(session.refreshToken).toHaveLength(128);
      expect(session.expiresIn).toBe(900);
      expect(session.user).not.toHaveProperty('passwordHash');
      expect(refreshTokenDelegate.create).toHaveBeenCalledTimes(1);
    });

    it('menolak registrasi dengan email duplikat (409 CONFLICT_ERROR)', async () => {
      usersService.findByEmail.mockResolvedValue(userFixture);

      await expect(
        service.register({
          name: 'Rayhan',
          email: 'RAYHAN@example.com',
          password: 'strong-password',
        }),
      ).rejects.toBeInstanceOf(ConflictException);

      expect(usersService.create).not.toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('menolak email yang tidak terdaftar dengan tetap menjalankan verifikasi dummy hash konstan', async () => {
      usersService.findByEmail.mockResolvedValue(null);

      await expect(
        service.login({ email: 'nobody@example.com', password: 'whatever' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      expect(argon2.verify).toHaveBeenCalledTimes(1);
    });

    it('menolak password yang salah', async () => {
      usersService.findByEmail.mockResolvedValue(userFixture);
      (argon2.verify as jest.Mock).mockResolvedValue(false);

      await expect(
        service.login({ email: 'rayhan@example.com', password: 'wrong' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('mengembalikan sesi baru untuk kredensial valid', async () => {
      usersService.findByEmail.mockResolvedValue(userFixture);

      const session = await service.login({
        email: 'Rayhan@Example.com',
        password: 'strong-password',
      });

      expect(usersService.findByEmail).toHaveBeenCalledWith(
        'rayhan@example.com',
      );
      expect(session.user.email).toBe('rayhan@example.com');
      expect(session.accessToken).toBe('signed.access.token');
    });
  });

  describe('refresh', () => {
    it('merotasi token: mencabut token lama dan menerbitkan pasangan baru', async () => {
      refreshTokenDelegate.findUnique.mockResolvedValue({
        id: 'rt-1',
        userId: 'user-1',
        tokenHash: 'hash',
        revokedAt: null,
        expiresAt: futureDate,
        createdAt: new Date(),
      });
      refreshTokenDelegate.updateMany.mockResolvedValue({ count: 1 });
      refreshTokenDelegate.create.mockResolvedValue({});
      userDelegate.findUniqueOrThrow.mockResolvedValue(userFixture);

      const session = await service.refresh('raw-refresh-token');

      expect(refreshTokenDelegate.updateMany).toHaveBeenCalledWith({
        where: { id: 'rt-1', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
      expect(refreshTokenDelegate.create).toHaveBeenCalledTimes(1);
      expect(session.refreshToken).not.toBe('raw-refresh-token');
      expect(session.refreshToken).toHaveLength(128);
    });

    it('mendeteksi reuse token revoked dan mencabut seluruh sesi aktif user', async () => {
      refreshTokenDelegate.findUnique.mockResolvedValue({
        id: 'rt-2',
        userId: 'user-1',
        tokenHash: 'hash',
        revokedAt: new Date(),
        expiresAt: futureDate,
        createdAt: new Date(),
      });
      refreshTokenDelegate.updateMany.mockResolvedValue({ count: 2 });

      let caught: UnauthorizedException | null = null;
      try {
        await service.refresh('reused-refresh-token');
      } catch (error) {
        caught = error as UnauthorizedException;
      }

      expect(caught).toBeInstanceOf(UnauthorizedException);
      expect(caught?.getResponse()).toMatchObject({
        code: 'TOKEN_REUSE_DETECTED',
      });
      expect(refreshTokenDelegate.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('menolak token yang tidak dikenal', async () => {
      refreshTokenDelegate.findUnique.mockResolvedValue(null);

      await expect(service.refresh('unknown-token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('menolak token yang sudah kedaluwarsa', async () => {
      refreshTokenDelegate.findUnique.mockResolvedValue({
        id: 'rt-3',
        userId: 'user-1',
        tokenHash: 'hash',
        revokedAt: null,
        expiresAt: new Date(Date.now() - 1000),
        createdAt: new Date(),
      });

      await expect(service.refresh('expired-token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });

  describe('logout', () => {
    it('mencabut token refresh secara idempotent', async () => {
      refreshTokenDelegate.updateMany.mockResolvedValue({ count: 1 });

      const result = await service.logout('raw-refresh-token');

      expect(result).toEqual({ revoked: true });
      expect(refreshTokenDelegate.updateMany).toHaveBeenCalledWith({
        where: { tokenHash: expect.any(String), revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
    });
  });

  describe('getProfile', () => {
    it('mengembalikan profil publik tanpa passwordHash', async () => {
      usersService.findById.mockResolvedValue(userFixture);

      const profile = await service.getProfile('user-1');

      expect(profile).not.toHaveProperty('passwordHash');
      expect(profile.email).toBe('rayhan@example.com');
    });

    it('menolak jika user sudah tidak ada', async () => {
      usersService.findById.mockResolvedValue(null);

      await expect(service.getProfile('ghost')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });
});
