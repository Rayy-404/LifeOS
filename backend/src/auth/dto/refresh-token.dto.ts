import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

/**
 * Request body for `POST /auth/refresh` and `POST /auth/logout`
 * (`03-technical-spec.md` Section 4.1). The refresh token is an opaque
 * random string; only its SHA-256 hash is persisted server-side.
 */
export class RefreshTokenDto {
  @ApiProperty({ description: 'Opaque refresh token issued by the API' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1024)
  refreshToken!: string;
}
