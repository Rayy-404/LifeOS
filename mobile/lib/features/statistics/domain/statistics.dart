import 'package:equatable/equatable.dart';

class StatisticsTaskMetrics extends Equatable {
  const StatisticsTaskMetrics({
    required this.total,
    required this.completed,
    required this.overdue,
    required this.completionRate,
  });

  final int total;
  final int completed;
  final int overdue;
  final double completionRate;

  factory StatisticsTaskMetrics.fromJson(Map<String, dynamic> json) {
    return StatisticsTaskMetrics(
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'completed': completed,
        'overdue': overdue,
        'completionRate': completionRate,
      };

  @override
  List<Object?> get props => [total, completed, overdue, completionRate];
}

class StatisticsHabitMetrics extends Equatable {
  const StatisticsHabitMetrics({
    required this.totalScheduledInstances,
    required this.totalCompletedInstances,
    required this.consistencyRate,
  });

  final int totalScheduledInstances;
  final int totalCompletedInstances;
  final double consistencyRate;

  factory StatisticsHabitMetrics.fromJson(Map<String, dynamic> json) {
    return StatisticsHabitMetrics(
      totalScheduledInstances:
          (json['totalScheduledInstances'] as num?)?.toInt() ?? 0,
      totalCompletedInstances:
          (json['totalCompletedInstances'] as num?)?.toInt() ?? 0,
      consistencyRate: (json['consistencyRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalScheduledInstances': totalScheduledInstances,
        'totalCompletedInstances': totalCompletedInstances,
        'consistencyRate': consistencyRate,
      };

  @override
  List<Object?> get props => [
        totalScheduledInstances,
        totalCompletedInstances,
        consistencyRate,
      ];
}

class StatisticsOverview extends Equatable {
  const StatisticsOverview({
    required this.from,
    required this.to,
    required this.tasks,
    required this.habits,
  });

  final String from;
  final String to;
  final StatisticsTaskMetrics tasks;
  final StatisticsHabitMetrics habits;

  factory StatisticsOverview.fromJson(Map<String, dynamic> json) {
    return StatisticsOverview(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      tasks: StatisticsTaskMetrics.fromJson(
        (json['tasks'] as Map<String, dynamic>?) ?? const {},
      ),
      habits: StatisticsHabitMetrics.fromJson(
        (json['habits'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'tasks': tasks.toJson(),
        'habits': habits.toJson(),
      };

  @override
  List<Object?> get props => [from, to, tasks, habits];
}

class WeeklyStatisticsDay extends Equatable {
  const WeeklyStatisticsDay({
    required this.date,
    required this.isoWeekday,
    required this.tasksCompleted,
    required this.habitsScheduled,
    required this.habitsCompleted,
  });

  final String date;
  final int isoWeekday;
  final int tasksCompleted;
  final int habitsScheduled;
  final int habitsCompleted;

  factory WeeklyStatisticsDay.fromJson(Map<String, dynamic> json) {
    return WeeklyStatisticsDay(
      date: json['date'] as String? ?? '',
      isoWeekday: (json['isoWeekday'] as num?)?.toInt() ?? 1,
      tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
      habitsScheduled: (json['habitsScheduled'] as num?)?.toInt() ?? 0,
      habitsCompleted: (json['habitsCompleted'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'isoWeekday': isoWeekday,
        'tasksCompleted': tasksCompleted,
        'habitsScheduled': habitsScheduled,
        'habitsCompleted': habitsCompleted,
      };

  @override
  List<Object?> get props => [
        date,
        isoWeekday,
        tasksCompleted,
        habitsScheduled,
        habitsCompleted,
      ];
}

class WeeklyStatistics extends Equatable {
  const WeeklyStatistics({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
  });

  final String weekStart;
  final String weekEnd;
  final List<WeeklyStatisticsDay> days;

  factory WeeklyStatistics.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List<dynamic>?) ?? const [];
    return WeeklyStatistics(
      weekStart: json['weekStart'] as String? ?? '',
      weekEnd: json['weekEnd'] as String? ?? '',
      days: rawDays
          .whereType<Map<String, dynamic>>()
          .map(WeeklyStatisticsDay.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'days': days.map((day) => day.toJson()).toList(),
      };

  @override
  List<Object?> get props => [weekStart, weekEnd, days];
}

class StatisticsBundle extends Equatable {
  const StatisticsBundle({
    required this.currentWeek,
    required this.previousWeek,
    required this.weekly,
    this.isFromCache = false,
  });

  final StatisticsOverview currentWeek;
  final StatisticsOverview previousWeek;
  final WeeklyStatistics weekly;
  final bool isFromCache;

  /// Positive when this week's completion rate improved vs last week.
  double get completionDelta =>
      currentWeek.tasks.completionRate - previousWeek.tasks.completionRate;

  factory StatisticsBundle.fromJson(Map<String, dynamic> json) {
    return StatisticsBundle(
      currentWeek: StatisticsOverview.fromJson(
        (json['currentWeek'] as Map<String, dynamic>?) ?? const {},
      ),
      previousWeek: StatisticsOverview.fromJson(
        (json['previousWeek'] as Map<String, dynamic>?) ?? const {},
      ),
      weekly: WeeklyStatistics.fromJson(
        (json['weekly'] as Map<String, dynamic>?) ?? const {},
      ),
      isFromCache: json['isFromCache'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentWeek': currentWeek.toJson(),
        'previousWeek': previousWeek.toJson(),
        'weekly': weekly.toJson(),
      };

  @override
  List<Object?> get props => [
        currentWeek,
        previousWeek,
        weekly,
        isFromCache,
      ];
}
