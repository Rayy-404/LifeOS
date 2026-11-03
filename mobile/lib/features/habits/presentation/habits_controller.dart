import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/state/data_revision_provider.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
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
    if (state.value == null) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() => _repository.listHabits());
  }

  /// Optimistically inserts a newly created habit immediately (< 50ms)
  /// and reconciles with the server response in the background.
  Future<Habit> createHabit({
    required String name,
    String? description,
    List<int> activeDays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    final now = DateTime.now();
    final tempId = 'temp_habit_${now.microsecondsSinceEpoch}';
    final tempHabit = Habit(
      id: tempId,
      name: name,
      description: description,
      isActive: true,
      activeDays: activeDays,
      currentStreak: 0,
      completedToday: false,
      createdAt: now,
      updatedAt: now,
    );

    final previousState = state.value;
    if (previousState != null) {
      state = AsyncData(
        HabitsSnapshot(
          items: [tempHabit, ...previousState.items],
          isFromCache: previousState.isFromCache,
        ),
      );
    }
    ref
        .read(dashboardControllerProvider.notifier)
        .optimisticInsertHabit(tempHabit);

    try {
      final created = await _repository.createHabit(
        name: name,
        description: description,
        activeDays: activeDays,
      );

      final current = state.value;
      if (current != null) {
        state = AsyncData(
          HabitsSnapshot(
            items: current.items
                .map((h) => h.id == tempId ? created : h)
                .toList(growable: false),
            isFromCache: current.isFromCache,
          ),
        );
      }
      _notifyDataChanged();
      return created;
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }

  Future<Habit> updateHabit(
    Habit existing, {
    String? name,
    String? description,
    bool includeNullDescription = false,
    List<int>? activeDays,
    bool? isActive,
  }) async {
    final previousState = state.value;
    final optimisticHabit = existing.copyWith(
      name: name ?? existing.name,
      description: description,
      clearDescription: includeNullDescription,
      activeDays: activeDays ?? existing.activeDays,
      isActive: isActive ?? existing.isActive,
      updatedAt: DateTime.now(),
    );

    if (previousState != null) {
      state = AsyncData(
        HabitsSnapshot(
          items: previousState.items
              .map((h) => h.id == existing.id ? optimisticHabit : h)
              .toList(growable: false),
          isFromCache: previousState.isFromCache,
        ),
      );
    }

    try {
      final updated = await _repository.updateHabit(
        existing.id,
        name: name,
        description: description,
        includeNullDescription: includeNullDescription,
        activeDays: activeDays,
        isActive: isActive,
      );

      final current = state.value;
      if (current != null) {
        state = AsyncData(
          HabitsSnapshot(
            items: current.items
                .map((h) => h.id == existing.id ? updated : h)
                .toList(growable: false),
            isFromCache: current.isFromCache,
          ),
        );
      }
      ref.invalidate(habitLogsProvider(existing.id));
      _notifyDataChanged();
      return updated;
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
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

    if (isToday) {
      ref
          .read(dashboardControllerProvider.notifier)
          .optimisticToggleHabit(habit, completed);
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
      if (isToday) {
        ref
            .read(dashboardControllerProvider.notifier)
            .optimisticToggleHabit(habit, !completed);
      }
      rethrow;
    }
  }

  void _notifyDataChanged() {
    ref.read(dataRevisionProvider.notifier).markChanged();
  }
}
