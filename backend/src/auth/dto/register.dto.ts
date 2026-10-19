import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsOptional,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';
import { IsValidTimezone } from '../../common/decorators/is-valid-timezone.decorator';

/**
 * `POST /auth/register` DTO (`03-technical-spec.md` Section 4.1).
 * Email is normalized to trimmed lowercase; timezone must be a valid IANA
 * identifier and defaults to `Asia/Jakarta`.
 */
export class RegisterDto {
  @ApiProperty({ example: 'Rayhan', minLength: 1, maxLength: 100 })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @Length(1, 100)
  name!: string;

  @ApiProperty({ example: 'rayhan@example.com', maxLength: 254 })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail()
  @MaxLength(254)
  email!: string;

  @ApiProperty({
    example: 'strong-password',
    minLength: 8,
    maxLength: 128,
    format: 'password',
  })
  @IsString()
  @Length(8, 128)
  password!: string;

  @ApiPropertyOptional({ example: 'Asia/Jakarta', default: 'Asia/Jakarta' })
  @IsOptional()
  @IsString()
  @IsValidTimezone()
  timezone?: string;
}
