import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/state/data_revision_provider.dart';
import '../data/habits_repository.dart';
import '../domain/habit.dart';

final habitsControllerProvider =
    AsyncNotifierProvider<HabitsController, HabitsSnapshot>(
  HabitsController.new,
);

final habitLogsProvider = FutureProvider.autoDispose.family<List<HabitLog>, String>(
  (ref, habitId) {
    final repo = ref.watch(habitsRepositoryProvider);
    return repo.getLogs(habitId);
  },
);

class HabitsController extends AsyncNotifier<HabitsSnapshot> {
  HabitsRepository get _repository => ref.read(habitsRepositoryProvider);

  @override
  Future<HabitsSnapshot> build() {
    return _repository.listHabits();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.listHabits());
  }

  Future<Habit> createHabit({
    required String name,
    String? description,
    List<int> activeDays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    final created = await _repository.createHabit(
      name: name,
      description: description,
      activeDays: activeDays,
    );
    ref.invalidateSelf();
    _notifyDataChanged();
    return created;
  }

  Future<Habit> updateHabit(
    Habit existing, {
    String? name,
    String? description,
    bool includeNullDescription = false,
    List<int>? activeDays,
    bool? isActive,
  }) async {
    final updated = await _repository.updateHabit(
      existing.id,
      name: name,
      description: description,
      includeNullDescription: includeNullDescription,
      activeDays: activeDays,
      isActive: isActive,
    );
    ref.invalidateSelf();
    ref.invalidate(habitLogsProvider(existing.id));
    _notifyDataChanged();
    return updated;
  }

  Future<void> deleteHabit(String id) async {
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncData(
        HabitsSnapshot(
          items: previousState.items.where((h) => h.id != id).toList(),
          isFromCache: previousState.isFromCache,
        ),
      );
    }

    try {
      await _repository.deleteHabit(id);
      _notifyDataChanged();
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }

  /// Optimistically toggles today's check-in (`02-design-brief.md` Section 5 & `DESIGN.md` S-08).
  Future<HabitCheckInResponse> toggleTodayCheckIn(Habit habit) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nextCompleted = !habit.completedToday;
    return checkInForDate(
      habit,
      dateStr: todayStr,
      completed: nextCompleted,
    );
  }

  Future<HabitCheckInResponse> checkInForDate(
    Habit habit, {
    required String dateStr,
    required bool completed,
  }) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = dateStr == todayStr;
    final previousState = state.value;

    if (previousState != null) {
      final optimisticItems = previousState.items.map((item) {
        if (item.id != habit.id) return item;

        final updatedWeekly = item.weeklyLogs.map((day) {
          if (day.date != dateStr) return day;
          return day.copyWith(completed: completed);
        }).toList();

        final nextStreak = isToday
            ? (completed
                ? item.currentStreak + 1
                : (item.currentStreak > 0 ? item.currentStreak - 1 : 0))
            : item.currentStreak;

        return item.copyWith(
          completedToday: isToday ? completed : item.completedToday,
          currentStreak: nextStreak,
          weeklyLogs: updatedWeekly,
        );
      }).toList();

      state = AsyncData(
        HabitsSnapshot(
          items: optimisticItems,
          isFromCache: previousState.isFromCache,
        ),
      );
    }

    try {
      final response = await _repository.checkIn(
        habit.id,
        date: dateStr,
        completed: completed,
      );

      final currentState = state.value;
      if (currentState != null) {
        final reconciled = currentState.items.map((item) {
          if (item.id != habit.id) return item;
          return item.copyWith(
            currentStreak: response.currentStreak,
            completedToday: isToday ? response.completed : item.completedToday,
          );
        }).toList();

        state = AsyncData(
          HabitsSnapshot(
            items: reconciled,
            isFromCache: currentState.isFromCache,
          ),
        );
      }

      ref.invalidate(habitLogsProvider(habit.id));
      _notifyDataChanged();
      return response;
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }

  void _notifyDataChanged() {
    ref.read(dataRevisionProvider.notifier).markChanged();
  }
}
