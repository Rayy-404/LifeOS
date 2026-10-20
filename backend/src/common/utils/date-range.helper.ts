import { BadRequestException } from '@nestjs/common';

export interface UtcInterval {
  startUtc: Date;
  endUtc: Date;
}

/**
 * Timezone-aware date & half-open interval `[startUtc, endUtc)` converter
 * (`03-technical-spec.md` Section 3.3 & `OD-05`).
 */
export class DateRangeHelper {
  private static readonly DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;

  static isValidTimezone(timezone: string): boolean {
    try {
      Intl.DateTimeFormat(undefined, { timeZone: timezone });
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Returns current local calendar date string `YYYY-MM-DD` in `timezone`.
   */
  static getTodayLocalDateString(
    timezone: string = 'Asia/Jakarta',
    now: Date = new Date(),
  ): string {
    const parts = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).formatToParts(now);

    const year = parts.find((p) => p.type === 'year')?.value;
    const month = parts.find((p) => p.type === 'month')?.value;
    const day = parts.find((p) => p.type === 'day')?.value;
    return `${year}-${month}-${day}`;
  }

  /**
   * Converts a local calendar date `YYYY-MM-DD` in `timezone` into a half-open
   * UTC interval `[dayStartUtc, dayEndUtc)` where `dayStartUtc` is `00:00:00.000`
   * on `dateStr` and `dayEndUtc` is `00:00:00.000` on `dateStr + 1 day`.
   */
  static getDayUtcInterval(
    dateStr: string,
    timezone: string = 'Asia/Jakarta',
  ): UtcInterval {
    this.assertValidCalendarDate(dateStr);

    const startUtc = this.localMidnightToUtc(dateStr, timezone);
    const nextDateStr = this.addDaysToDateString(dateStr, 1);
    const endUtc = this.localMidnightToUtc(nextDateStr, timezone);

    return { startUtc, endUtc };
  }

  /**
   * Converts `[from, to]` (either `YYYY-MM-DD` calendar dates or full ISO-8601 timestamps)
   * into a half-open UTC interval `[rangeStartUtc, rangeEndUtc)`.
   */
  static getRangeUtcInterval(
    from: string,
    to: string,
    timezone: string = 'Asia/Jakarta',
  ): UtcInterval {
    if (this.DATE_REGEX.test(from) && this.DATE_REGEX.test(to)) {
      this.assertValidCalendarDate(from, 'from');
      this.assertValidCalendarDate(to, 'to');
      if (from > to) {
        throw new BadRequestException({
          code: 'INVALID_TIME_RANGE',
          message: '"from" date must be less than or equal to "to" date.',
        });
      }
      const startUtc = this.localMidnightToUtc(from, timezone);
      const nextAfterTo = this.addDaysToDateString(to, 1);
      const endUtc = this.localMidnightToUtc(nextAfterTo, timezone);
      return { startUtc, endUtc };
    }

    if (this.DATE_REGEX.test(from) || this.DATE_REGEX.test(to)) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: '"from" and "to" must both use YYYY-MM-DD or ISO-8601 timestamps.',
      });
    }

    const startUtc = new Date(from);
    const endUtc = new Date(to);
    if (isNaN(startUtc.getTime()) || isNaN(endUtc.getTime())) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: 'Invalid ISO-8601 date/time range parameters.',
      });
    }
    if (startUtc >= endUtc) {
      throw new BadRequestException({
        code: 'INVALID_TIME_RANGE',
        message: '"from" timestamp must be strictly earlier than "to".',
      });
    }
    return { startUtc, endUtc };
  }

  private static assertValidCalendarDate(
    dateStr: string,
    fieldName = 'date',
  ): void {
    if (!this.DATE_REGEX.test(dateStr)) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: `Invalid ${fieldName} format "${dateStr}". Expected YYYY-MM-DD.`,
      });
    }

    const [year, month, day] = dateStr.split('-').map(Number);
    const date = new Date(Date.UTC(year, month - 1, day));
    if (
      isNaN(date.getTime()) ||
      date.toISOString().slice(0, 10) !== dateStr
    ) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: `Invalid calendar ${fieldName} "${dateStr}".`,
      });
    }
  }

  /**
   * Adds `days` to a `YYYY-MM-DD` string using pure calendar arithmetic.
   */
  static addDaysToDateString(dateStr: string, days: number): string {
    const [y, m, d] = dateStr.split('-').map(Number);
    const dt = new Date(Date.UTC(y, m - 1, d + days));
    return dt.toISOString().slice(0, 10);
  }

  /**
   * Returns ISO weekday `1` (Monday) .. `7` (Sunday) for a `YYYY-MM-DD` date string.
   */
  static getIsoWeekday(dateStr: string): number {
    const [y, m, d] = dateStr.split('-').map(Number);
    const dt = new Date(Date.UTC(y, m - 1, d));
    const day = dt.getUTCDay();
    return day === 0 ? 7 : day;
  }

  private static localMidnightToUtc(dateStr: string, timezone: string): Date {
    const [y, m, d] = dateStr.split('-').map(Number);
    const approxUtcMs = Date.UTC(y, m - 1, d, 0, 0, 0, 0);
    const offsetMs = this.getTimezoneOffsetMs(new Date(approxUtcMs), timezone);
    const candidateUtc = new Date(approxUtcMs - offsetMs);
    const refinedOffsetMs = this.getTimezoneOffsetMs(candidateUtc, timezone);
    return new Date(approxUtcMs - refinedOffsetMs);
  }

  private static getTimezoneOffsetMs(utcDate: Date, timezone: string): number {
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone,
      hour12: false,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    }).formatToParts(utcDate);

    const getPart = (type: string) =>
      Number(parts.find((p) => p.type === type)?.value ?? 0);

    const year = getPart('year');
    const month = getPart('month');
    const day = getPart('day');
    let hour = getPart('hour');
    if (hour === 24) hour = 0;
    const minute = getPart('minute');
    const second = getPart('second');

    const asUtcMs = Date.UTC(year, month - 1, day, hour, minute, second);
    const truncatedInputMs =
      Math.floor(utcDate.getTime() / 1000) * 1000;
    return asUtcMs - truncatedInputMs;
  }
}
