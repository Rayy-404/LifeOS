import 'package:intl/intl.dart';

/// Single unified UTC <-> Local date/time helper (`06-implementation-workflow-and-prompts.md` §6.5 #7).
abstract final class LocalDateTimeHelper {
  static final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _time24Format = DateFormat('HH:mm');
  static final DateFormat _time12Format = DateFormat('hh:mm a');

  /// Parses an ISO-8601 UTC string from the backend and converts it to local `DateTime`.
  static DateTime parseUtcToLocal(String isoString) {
    return DateTime.parse(isoString).toLocal();
  }

  /// Normalizes any `DateTime` into a midnight local date `(year, month, day)`.
  static DateTime normalizeLocalDay(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Formats a `DateTime` as a local calendar date key `YYYY-MM-DD`.
  static String toLocalDateKey(DateTime dt) {
    return _dateKeyFormat.format(dt.toLocal());
  }

  /// Returns today's local calendar date key `YYYY-MM-DD`.
  static String todayLocalDateKey([DateTime? now]) {
    return toLocalDateKey(now ?? DateTime.now());
  }

  /// Returns true if `[startsAt, endsAt)` overlaps the local day `[dayStart, dayEnd)`.
  static bool doesEventOverlapLocalDay(
    DateTime startsAt,
    DateTime endsAt,
    DateTime localDay,
  ) {
    final startLocal = startsAt.toLocal();
    final endLocal = endsAt.toLocal();
    final dayStart = DateTime(localDay.year, localDay.month, localDay.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return startLocal.isBefore(dayEnd) && endLocal.isAfter(dayStart);
  }

  static String formatTime24(DateTime dt) {
    return _time24Format.format(dt.toLocal());
  }

  static String formatTime12(DateTime dt) {
    return _time12Format.format(dt.toLocal());
  }

  static String formatTimeRange24(DateTime startsAt, DateTime endsAt) {
    return '${formatTime24(startsAt)} - ${formatTime24(endsAt)}';
  }

  static String greetingForNow([DateTime? now]) {
    final hour = (now ?? DateTime.now()).toLocal().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 18) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}
