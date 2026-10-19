import { DateRangeHelper } from './date-range.helper';

describe('DateRangeHelper', () => {
  it('converts 2026-10-18 in Asia/Jakarta (UTC+7) to half-open [startUtc, endUtc)', () => {
    const { startUtc, endUtc } = DateRangeHelper.getDayUtcInterval(
      '2026-10-18',
      'Asia/Jakarta',
    );

    expect(startUtc.toISOString()).toBe('2026-10-17T17:00:00.000Z');
    expect(endUtc.toISOString()).toBe('2026-10-18T17:00:00.000Z');
  });

  it('converts date range [from, to] in Asia/Jakarta to half-open interval', () => {
    const { startUtc, endUtc } = DateRangeHelper.getRangeUtcInterval(
      '2026-10-12',
      '2026-10-18',
      'Asia/Jakarta',
    );

    expect(startUtc.toISOString()).toBe('2026-10-11T17:00:00.000Z');
    expect(endUtc.toISOString()).toBe('2026-10-18T17:00:00.000Z');
  });

  it('computes ISO weekday 1 (Monday) to 7 (Sunday)', () => {
    expect(DateRangeHelper.getIsoWeekday('2026-10-12')).toBe(1); // Monday
    expect(DateRangeHelper.getIsoWeekday('2026-10-18')).toBe(7); // Sunday
  });

  it('rejects reversed date ranges', () => {
    expect(() =>
      DateRangeHelper.getRangeUtcInterval(
        '2026-10-19',
        '2026-10-18',
        'Asia/Jakarta',
      ),
    ).toThrow();
  });
});
