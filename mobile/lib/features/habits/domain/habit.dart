import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class WeeklyHabitLogItem extends Equatable {
  const WeeklyHabitLogItem({
    required this.date,
    required this.isoWeekday,
    required this.scheduled,
    required this.completed,
  });

  final String date;
  final int isoWeekday;
  final bool scheduled;
  final bool completed;

  WeeklyHabitLogItem copyWith({
    String? date,
    int? isoWeekday,
    bool? scheduled,
    bool? completed,
  }) {
    return WeeklyHabitLogItem(
      date: date ?? this.date,
      isoWeekday: isoWeekday ?? this.isoWeekday,
      scheduled: scheduled ?? this.scheduled,
      completed: completed ?? this.completed,
    );
  }

  factory WeeklyHabitLogItem.fromJson(Map<String, dynamic> json) {
    return WeeklyHabitLogItem(
      date: (json['date'] as String?) ?? '',
      isoWeekday: (json['isoWeekday'] as num?)?.toInt() ?? 1,
      scheduled: (json['scheduled'] as bool?) ?? true,
      completed: (json['completed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'isoWeekday': isoWeekday,
        'scheduled': scheduled,
        'completed': completed,
      };

  @override
  List<Object?> get props => [date, isoWeekday, scheduled, completed];
}

class HabitLog extends Equatable {
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.logDate,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final String logDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['logDate'] as String?) ?? '';
    return HabitLog(
      id: (json['id'] as String?) ?? '',
      habitId: (json['habitId'] as String?) ?? '',
      logDate: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)?.toLocal()
          : null,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String)?.toLocal() ??
              DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'logDate': logDate,
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => [id, habitId, logDate, completedAt, createdAt];
}

class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.activeDays = const [1, 2, 3, 4, 5, 6, 7],
    this.currentStreak = 0,
    this.completedToday = false,
    this.weeklyLogs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final List<int> activeDays;
  final int currentStreak;
  final bool completedToday;
  final List<WeeklyHabitLogItem> weeklyLogs;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get scheduledCountThisWeek {
    if (weeklyLogs.isEmpty) {
      return activeDays.isEmpty ? 7 : activeDays.length;
    }
    final count = weeklyLogs.where((d) => d.scheduled).length;
    return count == 0 ? 1 : count;
  }

  int get completedCountThisWeek =>
      weeklyLogs.where((d) => d.completed).length;

  double get weeklyProgressRatio =>
      (completedCountThisWeek / scheduledCountThisWeek).clamp(0.0, 1.0);

  bool isScheduledOnWeekday(int isoWeekday) =>
      activeDays.contains(isoWeekday);

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    bool clearDescription = false,
    bool? isActive,
    List<int>? activeDays,
    int? currentStreak,
    bool? completedToday,
    List<WeeklyHabitLogItem>? weeklyLogs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      isActive: isActive ?? this.isActive,
      activeDays: activeDays ?? this.activeDays,
      currentStreak: currentStreak ?? this.currentStreak,
      completedToday: completedToday ?? this.completedToday,
      weeklyLogs: weeklyLogs ?? this.weeklyLogs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawActiveDays = (json['activeDays'] as List<dynamic>?) ??
        const [1, 2, 3, 4, 5, 6, 7];
    final rawWeeklyLogs =
        (json['weeklyLogs'] as List<dynamic>?) ?? const [];

    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      activeDays: rawActiveDays.map((e) => (e as num).toInt()).toList(),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      completedToday: (json['completedToday'] as bool?) ?? false,
      weeklyLogs: rawWeeklyLogs
          .whereType<Map<String, dynamic>>()
          .map(WeeklyHabitLogItem.fromJson)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isActive': isActive,
        'activeDays': activeDays,
        'currentStreak': currentStreak,
        'completedToday': completedToday,
        'weeklyLogs': weeklyLogs.map((w) => w.toJson()).toList(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  /// Computes client-side Best Streak from log history (`06-implementation-workflow-and-prompts.md` §6.4 #8).
  int computeBestStreak(List<HabitLog> logs) {
    if (logs.isEmpty || activeDays.isEmpty) {
      return currentStreak;
    }

    final completedDates = logs.map((l) => l.logDate).toSet();
    final sorted = completedDates.toList()..sort();
    final earliest = DateTime.parse('${sorted.first}T00:00:00Z');
    final latest = DateTime.parse('${sorted.last}T00:00:00Z');
    final activeSet = activeDays.toSet();
    final fmt = DateFormat('yyyy-MM-dd');

    int best = currentStreak;
    int running = 0;
    var cursor = earliest;

    while (!cursor.isAfter(latest)) {
      final dateStr = fmt.format(cursor);
      final weekday = cursor.weekday; // 1 = Mon .. 7 = Sun
      if (activeSet.contains(weekday)) {
        if (completedDates.contains(dateStr)) {
          running += 1;
          if (running > best) {
            best = running;
          }
        } else {
          running = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return best;
  }

  /// Computes client-side Consistency % for a given month up to `today`.
  int computeMonthlyConsistencyPercent(
    List<HabitLog> logs,
    int year,
    int month, {
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final todayDate =
        DateTime(referenceNow.year, referenceNow.month, referenceNow.day);
    final firstDay = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final endEvaluation =
        lastDayOfMonth.isAfter(todayDate) ? todayDate : lastDayOfMonth;

    if (endEvaluation.isBefore(firstDay)) {
      return 0;
    }

    final completedDates = logs.map((l) => l.logDate).toSet();
    final activeSet = activeDays.toSet();
    final fmt = DateFormat('yyyy-MM-dd');

    int scheduledDays = 0;
    int completedScheduledDays = 0;

    var cursor = firstDay;
    while (!cursor.isAfter(endEvaluation)) {
      if (activeSet.contains(cursor.weekday)) {
        scheduledDays += 1;
        if (completedDates.contains(fmt.format(cursor))) {
          completedScheduledDays += 1;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (scheduledDays == 0) {
      return 100;
    }

    return ((completedScheduledDays / scheduledDays) * 100).round().clamp(0, 100);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isActive,
        activeDays,
        currentStreak,
        completedToday,
        weeklyLogs,
        createdAt,
        updatedAt,
      ];
}

class HabitsSnapshot extends Equatable {
  const HabitsSnapshot({
    required this.items,
    this.isFromCache = false,
  });

  final List<Habit> items;
  final bool isFromCache;

  @override
  List<Object?> get props => [items, isFromCache];
}
