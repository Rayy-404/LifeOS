import {
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import * as argon2 from 'argon2';
import { createHash, randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { DUMMY_ARGON2_HASH, normalizeEmail } from './auth.config';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

export interface PublicUser {
  id: string;
  name: string;
  email: string;
  timezone: string;
}

export interface AuthSessionPayload {
  user: PublicUser;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

type RefreshResult =
  | { kind: 'ok'; session: AuthSessionPayload }
  | { kind: 'invalid' }
  | { kind: 'expired' }
  | { kind: 'reuse'; userId: string };

const REFRESH_TOKEN_BYTES = 64;
const DEFAULT_ACCESS_TTL_SECONDS = 900;
const DEFAULT_REFRESH_TTL_DAYS = 30;

/**
 * Authentication service (`03-technical-spec.md` Sections 3 & 4.1):
 * Argon2id password hashing, short-lived JWT access tokens, opaque hashed
 * refresh tokens with atomic rotation and replay (reuse) detection.
 */
@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthSessionPayload> {
    const email = normalizeEmail(dto.email);

    const existing = await this.usersService.findByEmail(email);
    if (existing) {
      throw new ConflictException({
        code: 'CONFLICT_ERROR',
        message: 'Email is already registered',
      });
    }

    const passwordHash = await argon2.hash(dto.password, {
      type: argon2.argon2id,
    });

    const user = await this.usersService.create({
      email,
      passwordHash,
      name: dto.name.trim(),
      timezone: dto.timezone ?? 'Asia/Jakarta',
    });

    return this.createSession(user);
  }

  async login(dto: LoginDto): Promise<AuthSessionPayload> {
    const email = normalizeEmail(dto.email);
    const user = await this.usersService.findByEmail(email);

    const targetHash = user?.passwordHash ?? DUMMY_ARGON2_HASH;
    const passwordValid = await this.verifyPassword(targetHash, dto.password);

    if (!user || !passwordValid) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid email or password',
      });
    }

    return this.createSession(user);
  }

  /**
   * Atomically rotates a refresh token. Reuse of an already-revoked token
   * revokes ALL active refresh tokens of that user (`TOKEN_REUSE_DETECTED`).
   */
  async refresh(rawRefreshToken: string): Promise<AuthSessionPayload> {
    const tokenHash = AuthService.hashToken(rawRefreshToken);
    const now = new Date();

    const result = await this.prisma.$transaction(
      async (tx): Promise<RefreshResult> => {
        const storedToken = await tx.refreshToken.findUnique({
          where: { tokenHash },
        });

        if (!storedToken) {
          return { kind: 'invalid' };
        }
        if (storedToken.revokedAt) {
          await tx.refreshToken.updateMany({
            where: { userId: storedToken.userId, revokedAt: null },
            data: { revokedAt: now },
          });
          return { kind: 'reuse', userId: storedToken.userId };
        }
        if (storedToken.expiresAt <= now) {
          return { kind: 'expired' };
        }

        const rotated = await tx.refreshToken.updateMany({
          where: { id: storedToken.id, revokedAt: null },
          data: { revokedAt: now },
        });
        if (rotated.count === 0) {
          // Concurrent rotation of the same token: treat as replay and revoke all active sessions atomically.
          await tx.refreshToken.updateMany({
            where: { userId: storedToken.userId, revokedAt: null },
            data: { revokedAt: now },
          });
          return { kind: 'reuse', userId: storedToken.userId };
        }

        const user = await tx.user.findUniqueOrThrow({
          where: { id: storedToken.userId },
        });

        const newRawToken = AuthService.generateRefreshToken();
        await tx.refreshToken.create({
          data: {
            userId: user.id,
            tokenHash: AuthService.hashToken(newRawToken),
            expiresAt: this.nextRefreshExpiry(now),
          },
        });

        const accessToken = await this.signAccessToken(user);
        return {
          kind: 'ok',
          session: {
            user: AuthService.toPublicUser(user),
            accessToken,
            refreshToken: newRawToken,
            expiresIn: this.accessTtlSeconds(),
          },
        };
      },
    );

    if (result.kind === 'reuse') {
      this.logger.warn(
        `Refresh token reuse detected for user ${result.userId}; all active sessions revoked.`,
      );
      throw new UnauthorizedException({
        code: 'TOKEN_REUSE_DETECTED',
        message:
          'Refresh token reuse detected. All active sessions have been revoked.',
      });
    }
    if (result.kind === 'invalid') {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid refresh token',
      });
    }
    if (result.kind === 'expired') {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Refresh token has expired',
      });
    }

    return result.session;
  }

  /** Idempotent revocation of the provided refresh token. */
  async logout(rawRefreshToken: string): Promise<{ revoked: boolean }> {
    const tokenHash = AuthService.hashToken(rawRefreshToken);
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { revoked: true };
  }

  async getProfile(userId: string): Promise<PublicUser> {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authenticated user no longer exists',
      });
    }
    return AuthService.toPublicUser(user);
  }

  private async createSession(user: User): Promise<AuthSessionPayload> {
    const refreshToken = AuthService.generateRefreshToken();
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: AuthService.hashToken(refreshToken),
        expiresAt: this.nextRefreshExpiry(new Date()),
      },
    });

    const accessToken = await this.signAccessToken(user);
    return {
      user: AuthService.toPublicUser(user),
      accessToken,
      refreshToken,
      expiresIn: this.accessTtlSeconds(),
    };
  }

  private signAccessToken(user: User): Promise<string> {
    return this.jwtService.signAsync({
      sub: user.id,
      email: user.email,
      timezone: user.timezone,
    });
  }

  private async verifyPassword(
    passwordHash: string,
    password: string,
  ): Promise<boolean> {
    try {
      return await argon2.verify(passwordHash, password);
    } catch {
      return false;
    }
  }

  private nextRefreshExpiry(from: Date): Date {
    const ttlMs =
      this.refreshTtlDays() * 24 * 60 * 60 * 1000;
    return new Date(from.getTime() + ttlMs);
  }

  private refreshTtlDays(): number {
    const raw = this.configService.get<string>('REFRESH_TOKEN_TTL_DAYS');
    const parsed = raw ? Number.parseInt(raw, 10) : NaN;
    return Number.isFinite(parsed) && parsed > 0
      ? parsed
      : DEFAULT_REFRESH_TTL_DAYS;
  }

  private accessTtlSeconds(): number {
    const raw = this.configService.get<string>('JWT_ACCESS_TTL');
    return AuthService.parseDurationToSeconds(raw, DEFAULT_ACCESS_TTL_SECONDS);
  }

  private static parseDurationToSeconds(
    value: string | undefined,
    fallback: number,
  ): number {
    if (!value) {
      return fallback;
    }
    const match = /^(\d+)(s|m|h|d)?$/.exec(value.trim());
    if (!match) {
      return fallback;
    }
    const amount = Number.parseInt(match[1], 10);
    const unit = match[2] ?? 's';
    const multipliers: Record<string, number> = {
      s: 1,
      m: 60,
      h: 3600,
      d: 86400,
    };
    return amount * (multipliers[unit] ?? 1);
  }

  private static hashToken(rawToken: string): string {
    return createHash('sha256').update(rawToken).digest('hex');
  }

  private static generateRefreshToken(): string {
    return randomBytes(REFRESH_TOKEN_BYTES).toString('hex');
  }

  private static toPublicUser(user: User): PublicUser {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      timezone: user.timezone,
    };
  }
}
