import 'package:equatable/equatable.dart';
import '../../../core/utils/local_date_time_helper.dart';
import '../../tasks/domain/task.dart';

class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startsAt,
    required this.endsAt,
    required this.createdAt,
    required this.updatedAt,
    this.reminderIds = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> reminderIds;

  Duration get duration => endsAt.difference(startsAt);

  String get formattedTimeRange =>
      LocalDateTimeHelper.formatTimeRange24(startsAt, endsAt);

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? reminderIds,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      location: clearLocation ? null : (location ?? this.location),
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderIds: reminderIds ?? this.reminderIds,
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final rawReminders = json['reminders'] as List<dynamic>?;
    final reminderIds = rawReminders == null
        ? const <String>[]
        : rawReminders
            .whereType<Map<String, dynamic>>()
            .map((r) => r['id'] as String?)
            .whereType<String>()
            .toList();

    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startsAt: LocalDateTimeHelper.parseUtcToLocal(json['startsAt'] as String),
      endsAt: LocalDateTimeHelper.parseUtcToLocal(json['endsAt'] as String),
      createdAt: json['createdAt'] != null
          ? LocalDateTimeHelper.parseUtcToLocal(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? LocalDateTimeHelper.parseUtcToLocal(json['updatedAt'] as String)
          : DateTime.now(),
      reminderIds: reminderIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'EVENT',
        'title': title,
        'description': description,
        'location': location,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'reminders': reminderIds
            .map((id) => <String, dynamic>{'id': id})
            .toList(growable: false),
      };

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        location,
        startsAt,
        endsAt,
        createdAt,
        updatedAt,
        reminderIds,
      ];
}

enum AgendaEntryType { event, task }

class CalendarAgendaEntry extends Equatable {
  const CalendarAgendaEntry._({
    required this.type,
    required this.timestamp,
    this.event,
    this.task,
  });

  factory CalendarAgendaEntry.fromEvent(CalendarEvent event) {
    return CalendarAgendaEntry._(
      type: AgendaEntryType.event,
      timestamp: event.startsAt,
      event: event,
    );
  }

  factory CalendarAgendaEntry.fromTask(Task task) {
    return CalendarAgendaEntry._(
      type: AgendaEntryType.task,
      timestamp: task.dueAt ?? task.createdAt,
      task: task,
    );
  }

  final AgendaEntryType type;
  final DateTime timestamp;
  final CalendarEvent? event;
  final Task? task;

  bool get isEvent => type == AgendaEntryType.event;
  bool get isTask => type == AgendaEntryType.task;

  @override
  List<Object?> get props => [type, timestamp, event, task];
}

class CalendarAgendaSnapshot extends Equatable {
  const CalendarAgendaSnapshot({
    required this.from,
    required this.to,
    required this.events,
    required this.tasks,
    this.isFromCache = false,
  });

  final String from;
  final String to;
  final List<CalendarEvent> events;
  final List<Task> tasks;
  final bool isFromCache;

  List<CalendarEvent> eventsForDay(DateTime day) {
    final normalized = LocalDateTimeHelper.normalizeLocalDay(day);
    final filtered = events
        .where(
          (e) => LocalDateTimeHelper.doesEventOverlapLocalDay(
            e.startsAt,
            e.endsAt,
            normalized,
          ),
        )
        .toList();
    filtered.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return filtered;
  }

  List<Task> tasksForDay(DateTime day) {
    final key = LocalDateTimeHelper.toLocalDateKey(day);
    final filtered = tasks.where((t) {
      if (t.dueAt == null) return false;
      return LocalDateTimeHelper.toLocalDateKey(t.dueAt!) == key;
    }).toList();
    filtered.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return filtered;
  }

  List<CalendarAgendaEntry> combinedEntriesForDay(DateTime day) {
    final entries = <CalendarAgendaEntry>[
      ...eventsForDay(day).map(CalendarAgendaEntry.fromEvent),
      ...tasksForDay(day).map(CalendarAgendaEntry.fromTask),
    ];
    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return entries;
  }

  @override
  List<Object?> get props => [from, to, events, tasks, isFromCache];
}
