import 'package:equatable/equatable.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../habits/domain/habit.dart';
import '../../tasks/domain/task.dart';

class DashboardTasksSummary extends Equatable {
  const DashboardTasksSummary({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });

  final int total;
  final int completed;
  final int pending;
  final int overdue;

  double get completionRatio {
    if (total <= 0) return 0.0;
    return (completed / total).clamp(0.0, 1.0);
  }

  int get completionPercent => (completionRatio * 100).round();

  DashboardTasksSummary copyWith({
    int? total,
    int? completed,
    int? pending,
    int? overdue,
  }) {
    return DashboardTasksSummary(
      total: total ?? this.total,
      completed: completed ?? this.completed,
      pending: pending ?? this.pending,
      overdue: overdue ?? this.overdue,
    );
  }

  factory DashboardTasksSummary.fromJson(Map<String, dynamic> json) {
    return DashboardTasksSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'completed': completed,
        'pending': pending,
        'overdue': overdue,
      };

  @override
  List<Object?> get props => [total, completed, pending, overdue];
}

class DashboardHabitsSummary extends Equatable {
  const DashboardHabitsSummary({
    required this.scheduled,
    required this.completed,
  });

  final int scheduled;
  final int completed;

  DashboardHabitsSummary copyWith({
    int? scheduled,
    int? completed,
  }) {
    return DashboardHabitsSummary(
      scheduled: scheduled ?? this.scheduled,
      completed: completed ?? this.completed,
    );
  }

  factory DashboardHabitsSummary.fromJson(Map<String, dynamic> json) {
    return DashboardHabitsSummary(
      scheduled: (json['scheduled'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'scheduled': scheduled,
        'completed': completed,
      };

  @override
  List<Object?> get props => [scheduled, completed];
}

class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    required this.date,
    required this.timezone,
    required this.tasks,
    required this.habits,
    required this.upcomingEvents,
    required this.todayTasks,
    required this.todayHabits,
    this.isFromCache = false,
  });

  final String date;
  final String timezone;
  final DashboardTasksSummary tasks;
  final DashboardHabitsSummary habits;
  final List<CalendarEvent> upcomingEvents;
  final List<Task> todayTasks;
  final List<Habit> todayHabits;
  final bool isFromCache;

  DashboardSnapshot copyWith({
    String? date,
    String? timezone,
    DashboardTasksSummary? tasks,
    DashboardHabitsSummary? habits,
    List<CalendarEvent>? upcomingEvents,
    List<Task>? todayTasks,
    List<Habit>? todayHabits,
    bool? isFromCache,
  }) {
    return DashboardSnapshot(
      date: date ?? this.date,
      timezone: timezone ?? this.timezone,
      tasks: tasks ?? this.tasks,
      habits: habits ?? this.habits,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      todayTasks: todayTasks ?? this.todayTasks,
      todayHabits: todayHabits ?? this.todayHabits,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  factory DashboardSnapshot.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    final rawEvents = (json['upcomingEvents'] as List<dynamic>?) ?? const [];
    final rawTasks = (json['todayTasks'] as List<dynamic>?) ?? const [];
    final rawHabits = (json['todayHabits'] as List<dynamic>?) ?? const [];

    return DashboardSnapshot(
      date: (json['date'] as String?) ?? '',
      timezone: (json['timezone'] as String?) ?? 'Asia/Jakarta',
      tasks: DashboardTasksSummary.fromJson(
        (json['tasks'] as Map<String, dynamic>?) ?? const {},
      ),
      habits: DashboardHabitsSummary.fromJson(
        (json['habits'] as Map<String, dynamic>?) ?? const {},
      ),
      upcomingEvents: rawEvents
          .whereType<Map<String, dynamic>>()
          .map(CalendarEvent.fromJson)
          .toList(),
      todayTasks: rawTasks
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList(),
      todayHabits: rawHabits
          .whereType<Map<String, dynamic>>()
          .map(Habit.fromJson)
          .toList(),
      isFromCache: isFromCache,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'timezone': timezone,
        'tasks': tasks.toJson(),
        'habits': habits.toJson(),
        'upcomingEvents': upcomingEvents.map((e) => e.toJson()).toList(),
        'todayTasks': todayTasks.map((t) => t.toJson()).toList(),
        'todayHabits': todayHabits.map((h) => h.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        date,
        timezone,
        tasks,
        habits,
        upcomingEvents,
        todayTasks,
        todayHabits,
        isFromCache,
      ];
}
