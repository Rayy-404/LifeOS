import { registerDecorator, ValidationOptions } from 'class-validator';
import { DateRangeHelper } from '../utils/date-range.helper';

/**
 * Validates that the value is a valid IANA timezone identifier
 * (e.g. `Asia/Jakarta`), used by `RegisterDto` (`03-technical-spec.md` Section 4.1).
 */
export function IsValidTimezone(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string): void {
    registerDecorator({
      name: 'isValidTimezone',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: unknown): boolean {
          return (
            typeof value === 'string' &&
            value.length > 0 &&
            DateRangeHelper.isValidTimezone(value)
          );
        },
        defaultMessage(): string {
          return '$property must be a valid IANA timezone identifier';
        },
      },
    });
  };
}
