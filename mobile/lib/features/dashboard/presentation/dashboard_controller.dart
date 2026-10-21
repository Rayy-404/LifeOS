import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/data_revision_provider.dart';
import '../../../core/utils/local_date_time_helper.dart';
import '../../habits/domain/habit.dart';
import '../../habits/presentation/habits_controller.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/tasks_controller.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSnapshot>(
  DashboardController.new,
);

class DashboardController extends AsyncNotifier<DashboardSnapshot> {
  DashboardRepository get _repository => ref.read(dashboardRepositoryProvider);

  @override
  Future<DashboardSnapshot> build() {
    ref.watch(dataRevisionProvider);
    final todayKey = LocalDateTimeHelper.todayLocalDateKey();
    return _repository.getToday(date: todayKey);
  }

  Future<void> refresh() async {
    final todayKey = LocalDateTimeHelper.todayLocalDateKey();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getToday(date: todayKey));
  }

  /// 1-tap task toggle from Dashboard S-04 with optimistic update and cross-feature invalidation.
  Future<void> toggleTaskDone(Task task) async {
    await ref.read(tasksControllerProvider.notifier).toggleTaskDone(task);
  }

  /// 1-tap habit check-in from Dashboard S-04 with optimistic update and cross-feature invalidation.
  Future<void> toggleHabitCheckIn(Habit habit) async {
    await ref.read(habitsControllerProvider.notifier).toggleTodayCheckIn(habit);
  }
}
