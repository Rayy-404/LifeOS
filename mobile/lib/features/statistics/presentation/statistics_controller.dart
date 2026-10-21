import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/data_revision_provider.dart';
import '../../../core/utils/local_date_time_helper.dart';
import '../data/statistics_repository.dart';
import '../domain/statistics.dart';

final statisticsControllerProvider =
    AsyncNotifierProvider<StatisticsController, StatisticsBundle>(
  StatisticsController.new,
);

/// Loads the current week, previous week, and weekly trend in parallel.
class StatisticsController extends AsyncNotifier<StatisticsBundle> {
  StatisticsRepository get _repository =>
      ref.read(statisticsRepositoryProvider);

  @override
  Future<StatisticsBundle> build() {
    ref.watch(dataRevisionProvider);
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<StatisticsBundle> _fetch() {
    final today = LocalDateTimeHelper.normalizeLocalDay(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final previousMonday = monday.subtract(const Duration(days: 7));
    final previousSunday = monday.subtract(const Duration(days: 1));

    return _repository.getBundle(
      weekStart: LocalDateTimeHelper.toLocalDateKey(monday),
      weekEnd: LocalDateTimeHelper.toLocalDateKey(sunday),
      previousWeekStart: LocalDateTimeHelper.toLocalDateKey(previousMonday),
      previousWeekEnd: LocalDateTimeHelper.toLocalDateKey(previousSunday),
    );
  }
}
