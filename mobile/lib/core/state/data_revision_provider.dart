import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monotonic revision bumped after every successful domain mutation.
///
/// Aggregated views (`DashboardController`, `CalendarController`) watch this
/// signal so they refetch when a Task, Habit, or CalendarEvent is mutated from
/// another tab, instead of showing stale cached data.
final dataRevisionProvider = NotifierProvider<DataRevisionNotifier, int>(
  DataRevisionNotifier.new,
);

class DataRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void markChanged() => state++;
}
