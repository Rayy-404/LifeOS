import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/data_revision_provider.dart';
import '../../../core/utils/local_date_time_helper.dart';
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
    ref.watch(dataRevisionProvider);
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchForMonth(monthStart));
  }

  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final created = await _repository.createEvent(
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    _notifyDataChanged();
    return created;
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
    _notifyDataChanged();
    return updated;
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    await _repository.deleteEvent(
      event.id,
      reminderIdsToCancel: event.reminderIds,
    );
    _notifyDataChanged();
  }

  void _notifyDataChanged() {
    ref.read(dataRevisionProvider.notifier).markChanged();
  }
}
