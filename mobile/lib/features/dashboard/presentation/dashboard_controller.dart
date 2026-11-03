import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/data_revision_provider.dart';
import '../../../core/utils/local_date_time_helper.dart';
import '../../calendar/domain/calendar_event.dart';
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
    // Listen to data revisions for silent background reconciliation without
    // resetting state to AsyncLoading (prevents UI flicker on 2GB RAM devices).
    ref.listen<int>(dataRevisionProvider, (_, _) {
      unawaited(silentRefresh());
    });
    final todayKey = LocalDateTimeHelper.todayLocalDateKey();
    return _repository.getToday(date: todayKey);
  }

  Future<void> refresh() async {
    final todayKey = LocalDateTimeHelper.todayLocalDateKey();
    if (state.value == null) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() => _repository.getToday(date: todayKey));
  }

  /// Refreshes dashboard data in the background without triggering loading shimmers.
  Future<void> silentRefresh() async {
    try {
      final todayKey = LocalDateTimeHelper.todayLocalDateKey();
      final fresh = await _repository.getToday(date: todayKey);
      state = AsyncData(fresh);
    } catch (_) {
      // Keep existing optimistic/cached state when background refresh fails.
    }
  }

  /// Optimistically inserts a newly created task into today's dashboard snapshot.
  void optimisticInsertTask(Task task) {
    final current = state.value;
    if (current == null) return;

    final updatedTodayTasks = [task, ...current.todayTasks];
    final updatedSummary = current.tasks.copyWith(
      total: current.tasks.total + 1,
      pending: task.isDone ? current.tasks.pending : current.tasks.pending + 1,
      completed:
          task.isDone ? current.tasks.completed + 1 : current.tasks.completed,
      overdue: task.isOverdue()
          ? current.tasks.overdue + 1
          : current.tasks.overdue,
    );

    state = AsyncData(
      current.copyWith(
        tasks: updatedSummary,
        todayTasks: updatedTodayTasks,
      ),
    );
  }

  /// Optimistically replaces a task (e.g., tempId -> real server task, or status toggle).
  void optimisticReplaceTask(String targetId, Task updated) {
    final current = state.value;
    if (current == null) return;

    final existingIndex =
        current.todayTasks.indexWhere((t) => t.id == targetId);
    if (existingIndex == -1) return;

    final oldTask = current.todayTasks[existingIndex];
    final nextTasks = [...current.todayTasks];
    nextTasks[existingIndex] = updated;

    var completed = current.tasks.completed;
    var pending = current.tasks.pending;
    if (!oldTask.isDone && updated.isDone) {
      completed += 1;
      pending = (pending - 1).clamp(0, 999999);
    } else if (oldTask.isDone && !updated.isDone) {
      completed = (completed - 1).clamp(0, 999999);
      pending += 1;
    }

    state = AsyncData(
      current.copyWith(
        tasks: current.tasks.copyWith(
          completed: completed,
          pending: pending,
        ),
        todayTasks: nextTasks,
      ),
    );
  }

  /// Optimistically removes a task from today's dashboard snapshot (rollback or delete).
  void optimisticRemoveTask(String taskId) {
    final current = state.value;
    if (current == null) return;

    final existing =
        current.todayTasks.where((t) => t.id == taskId).firstOrNull;
    if (existing == null) return;

    final nextTasks =
        current.todayTasks.where((t) => t.id != taskId).toList();
    state = AsyncData(
      current.copyWith(
        tasks: current.tasks.copyWith(
          total: (current.tasks.total - 1).clamp(0, 999999),
          completed: existing.isDone
              ? (current.tasks.completed - 1).clamp(0, 999999)
              : current.tasks.completed,
          pending: !existing.isDone
              ? (current.tasks.pending - 1).clamp(0, 999999)
              : current.tasks.pending,
        ),
        todayTasks: nextTasks,
      ),
    );
  }

  /// Optimistically updates a habit check-in on the dashboard.
  void optimisticToggleHabit(Habit habit, bool completed) {
    final current = state.value;
    if (current == null) return;

    final idx = current.todayHabits.indexWhere((h) => h.id == habit.id);
    if (idx == -1) return;

    final oldHabit = current.todayHabits[idx];
    if (oldHabit.completedToday == completed) return;

    final nextStreak = completed
        ? oldHabit.currentStreak + 1
        : (oldHabit.currentStreak > 0 ? oldHabit.currentStreak - 1 : 0);
    final nextHabits = [...current.todayHabits];
    nextHabits[idx] = oldHabit.copyWith(
      completedToday: completed,
      currentStreak: nextStreak,
    );

    final nextCompletedCount = completed
        ? current.habits.completed + 1
        : (current.habits.completed - 1).clamp(0, 999999);

    state = AsyncData(
      current.copyWith(
        habits: current.habits.copyWith(completed: nextCompletedCount),
        todayHabits: nextHabits,
      ),
    );
  }

  /// Optimistically inserts a newly created habit into today's dashboard snapshot.
  void optimisticInsertHabit(Habit habit) {
    final current = state.value;
    if (current == null) return;
    final todayWeekday = DateTime.now().weekday;
    if (!habit.activeDays.contains(todayWeekday)) return;

    state = AsyncData(
      current.copyWith(
        habits: current.habits.copyWith(
          scheduled: current.habits.scheduled + 1,
        ),
        todayHabits: [habit, ...current.todayHabits],
      ),
    );
  }

  /// Optimistically inserts a newly created event into today's dashboard snapshot.
  void optimisticInsertEvent(CalendarEvent event) {
    final current = state.value;
    if (current == null) return;
    final today = LocalDateTimeHelper.normalizeLocalDay(DateTime.now());
    if (!LocalDateTimeHelper.doesEventOverlapLocalDay(
      event.startsAt,
      event.endsAt,
      today,
    )) {
      return;
    }
    final nextEvents = [...current.upcomingEvents, event]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    state = AsyncData(current.copyWith(upcomingEvents: nextEvents));
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
