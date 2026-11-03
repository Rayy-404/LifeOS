import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/data_revision_provider.dart';
import '../../../core/utils/local_date_time_helper.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../data/calendar_repository.dart';
import '../domain/calendar_event.dart';

class CalendarViewState extends Equatable {
  const CalendarViewState({
    required this.selectedDay,
    required this.focusedDay,
    this.isWeekMode = true,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final bool isWeekMode;

  CalendarViewState copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    bool? isWeekMode,
  }) {
    return CalendarViewState(
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      isWeekMode: isWeekMode ?? this.isWeekMode,
    );
  }

  @override
  List<Object?> get props => [selectedDay, focusedDay, isWeekMode];
}

final calendarViewProvider =
    NotifierProvider<CalendarViewNotifier, CalendarViewState>(
  CalendarViewNotifier.new,
);

class CalendarViewNotifier extends Notifier<CalendarViewState> {
  @override
  CalendarViewState build() {
    final today = LocalDateTimeHelper.normalizeLocalDay(DateTime.now());
    return CalendarViewState(selectedDay: today, focusedDay: today);
  }

  void selectDay(DateTime selected, DateTime focused) {
    state = state.copyWith(
      selectedDay: LocalDateTimeHelper.normalizeLocalDay(selected),
      focusedDay: LocalDateTimeHelper.normalizeLocalDay(focused),
    );
  }

  void jumpToToday() {
    final today = LocalDateTimeHelper.normalizeLocalDay(DateTime.now());
    state = state.copyWith(selectedDay: today, focusedDay: today);
  }

  void setFocusedDay(DateTime focused) {
    state = state.copyWith(
      focusedDay: LocalDateTimeHelper.normalizeLocalDay(focused),
    );
  }

  void setWeekMode(bool isWeekMode) {
    state = state.copyWith(isWeekMode: isWeekMode);
  }
}

final calendarControllerProvider =
    AsyncNotifierProvider<CalendarController, CalendarAgendaSnapshot>(
  CalendarController.new,
);

class CalendarController extends AsyncNotifier<CalendarAgendaSnapshot> {
  CalendarRepository get _repository => ref.read(calendarRepositoryProvider);

  @override
  Future<CalendarAgendaSnapshot> build() async {
    ref.listen<int>(dataRevisionProvider, (_, _) {
      unawaited(silentRefresh());
    });
    final focused = ref.watch(
      calendarViewProvider.select(
        (s) => DateTime(s.focusedDay.year, s.focusedDay.month, 1),
      ),
    );
    return _fetchForMonth(focused);
  }

  Future<CalendarAgendaSnapshot> _fetchForMonth(DateTime monthStart) {
    final fromDate = monthStart.subtract(const Duration(days: 7));
    final nextMonthEnd = DateTime(monthStart.year, monthStart.month + 2, 0);
    final toDate = nextMonthEnd.add(const Duration(days: 7));
    return _repository.listAgenda(
      from: LocalDateTimeHelper.toLocalDateKey(fromDate),
      to: LocalDateTimeHelper.toLocalDateKey(toDate),
    );
  }

  Future<void> refresh() async {
    final focused = ref.read(calendarViewProvider).focusedDay;
    final monthStart = DateTime(focused.year, focused.month, 1);
    if (state.value == null) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() => _fetchForMonth(monthStart));
  }

  Future<void> silentRefresh() async {
    try {
      final focused = ref.read(calendarViewProvider).focusedDay;
      final monthStart = DateTime(focused.year, focused.month, 1);
      final fresh = await _fetchForMonth(monthStart);
      state = AsyncData(fresh);
    } catch (_) {
      // Preserve optimistic/cached state if background sync fails.
    }
  }

  /// Optimistically inserts a temporary event into local calendar state (< 50ms)
  /// before syncing with the backend.
  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final now = DateTime.now();
    final tempId = 'temp_event_${now.microsecondsSinceEpoch}';
    final tempEvent = CalendarEvent(
      id: tempId,
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      createdAt: now,
      updatedAt: now,
    );

    final previousState = state.value;
    if (previousState != null) {
      final updatedEvents = [...previousState.events, tempEvent]
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      state = AsyncData(
        CalendarAgendaSnapshot(
          from: previousState.from,
          to: previousState.to,
          events: updatedEvents,
          tasks: previousState.tasks,
          isFromCache: previousState.isFromCache,
        ),
      );
    }
    ref
        .read(dashboardControllerProvider.notifier)
        .optimisticInsertEvent(tempEvent);

    try {
      final created = await _repository.createEvent(
        title: title,
        description: description,
        location: location,
        startsAt: startsAt,
        endsAt: endsAt,
      );

      final current = state.value;
      if (current != null) {
        final reconciled = current.events
            .map((e) => e.id == tempId ? created : e)
            .toList(growable: false);
        state = AsyncData(
          CalendarAgendaSnapshot(
            from: current.from,
            to: current.to,
            events: reconciled,
            tasks: current.tasks,
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

  Future<CalendarEvent> updateEvent(
    CalendarEvent existing, {
    String? title,
    String? description,
    bool includeNullDescription = false,
    String? location,
    bool includeNullLocation = false,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final previousState = state.value;
    final optimisticEvent = existing.copyWith(
      title: title ?? existing.title,
      description: description,
      clearDescription: includeNullDescription,
      location: location,
      clearLocation: includeNullLocation,
      startsAt: startsAt ?? existing.startsAt,
      endsAt: endsAt ?? existing.endsAt,
      updatedAt: DateTime.now(),
    );

    if (previousState != null) {
      state = AsyncData(
        CalendarAgendaSnapshot(
          from: previousState.from,
          to: previousState.to,
          events: previousState.events
              .map((e) => e.id == existing.id ? optimisticEvent : e)
              .toList(growable: false),
          tasks: previousState.tasks,
          isFromCache: previousState.isFromCache,
        ),
      );
    }

    try {
      final updated = await _repository.updateEvent(
        existing.id,
        title: title,
        description: description,
        includeNullDescription: includeNullDescription,
        location: location,
        includeNullLocation: includeNullLocation,
        startsAt: startsAt,
        endsAt: endsAt,
      );

      final current = state.value;
      if (current != null) {
        state = AsyncData(
          CalendarAgendaSnapshot(
            from: current.from,
            to: current.to,
            events: current.events
                .map((e) => e.id == existing.id ? updated : e)
                .toList(growable: false),
            tasks: current.tasks,
            isFromCache: current.isFromCache,
          ),
        );
      }
      _notifyDataChanged();
      return updated;
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncData(
        CalendarAgendaSnapshot(
          from: previousState.from,
          to: previousState.to,
          events: previousState.events
              .where((e) => e.id != event.id)
              .toList(growable: false),
          tasks: previousState.tasks,
          isFromCache: previousState.isFromCache,
        ),
      );
    }

    try {
      await _repository.deleteEvent(
        event.id,
        reminderIdsToCancel: event.reminderIds,
      );
      _notifyDataChanged();
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
