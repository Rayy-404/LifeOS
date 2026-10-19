import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsEmail, IsNotEmpty, IsString, MaxLength } from 'class-validator';

/**
 * `POST /auth/login` DTO (`03-technical-spec.md` Section 4.1).
 */
export class LoginDto {
  @ApiProperty({ example: 'rayhan@example.com', maxLength: 254 })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail()
  @MaxLength(254)
  email!: string;

  @ApiProperty({ example: 'strong-password', format: 'password' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(128)
  password!: string;
}
