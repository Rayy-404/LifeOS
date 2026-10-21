import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { UsersService } from '../../users/users.service';
import { getJwtAccessSecret } from '../auth.config';

export interface JwtPayload {
  sub: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
    private readonly usersService: UsersService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: getJwtAccessSecret(configService),
    });
  }

  /**
   * Security audit F6/F7: the token only carries the subject id, so profile
   * data (email, timezone) is always read from the database. A deleted account
   * therefore loses access immediately, without waiting for token expiry.
   */
  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    const user = await this.usersService.findById(payload.sub);
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authenticated user no longer exists',
      });
    }

    return {
      id: user.id,
      email: user.email,
      timezone: user.timezone,
    };
  }
}
