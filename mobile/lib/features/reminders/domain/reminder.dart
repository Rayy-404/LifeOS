import 'package:equatable/equatable.dart';
import '../../../core/utils/local_date_time_helper.dart';
import '../../tasks/domain/task.dart';

enum ReminderStatus {
  scheduled('SCHEDULED', 'Scheduled'),
  sent('SENT', 'Sent'),
  cancelled('CANCELLED', 'Cancelled'),
  failed('FAILED', 'Failed');

  const ReminderStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ReminderStatus fromApi(String? value) {
    switch (value) {
      case 'SENT':
        return ReminderStatus.sent;
      case 'CANCELLED':
        return ReminderStatus.cancelled;
      case 'FAILED':
        return ReminderStatus.failed;
      case 'SCHEDULED':
      default:
        return ReminderStatus.scheduled;
    }
  }
}

enum ReminderChannel {
  local('LOCAL'),
  push('PUSH');

  const ReminderChannel(this.apiValue);
  final String apiValue;

  static ReminderChannel fromApi(String? value) {
    return value == 'PUSH' ? ReminderChannel.push : ReminderChannel.local;
  }
}

/// Reminder entity mirroring `GET /api/v1/reminders` (`03-technical-spec.md` §4.5).
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    this.taskId,
    this.eventId,
    required this.remindAt,
    required this.status,
    required this.channel,
    required this.createdAt,
    required this.updatedAt,
    this.taskTitle,
    this.eventTitle,
    this.taskStatus,
  });

  final String id;
  final String? taskId;
  final String? eventId;
  final DateTime remindAt;
  final ReminderStatus status;
  final ReminderChannel channel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? taskTitle;
  final String? eventTitle;
  final TaskStatus? taskStatus;

  bool get isScheduled => status == ReminderStatus.scheduled;
  bool get isTaskReminder => taskId != null;
  String get targetTitle => taskTitle ?? eventTitle ?? 'Reminder';
  bool get isOverdue =>
      isScheduled && remindAt.isBefore(DateTime.now());

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>?;
    final event = json['event'] as Map<String, dynamic>?;

    return Reminder(
      id: json['id'] as String,
      taskId: json['taskId'] as String?,
      eventId: json['eventId'] as String?,
      remindAt: LocalDateTimeHelper.parseUtcToLocal(
        json['remindAt'] as String,
      ),
      status: ReminderStatus.fromApi(json['status'] as String?),
      channel: ReminderChannel.fromApi(json['channel'] as String?),
      createdAt: json['createdAt'] != null
          ? LocalDateTimeHelper.parseUtcToLocal(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? LocalDateTimeHelper.parseUtcToLocal(json['updatedAt'] as String)
          : DateTime.now(),
      taskTitle: task?['title'] as String?,
      eventTitle: event?['title'] as String?,
      taskStatus: task?['status'] != null
          ? TaskStatus.fromApi(task?['status'] as String?)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'eventId': eventId,
      'remindAt': remindAt.toUtc().toIso8601String(),
      'status': status.apiValue,
      'channel': channel.apiValue,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      if (taskId != null)
        'task': {
          'id': taskId,
          'title': taskTitle,
          'status': taskStatus?.apiValue,
        },
      if (eventId != null)
        'event': {
          'id': eventId,
          'title': eventTitle,
        },
    };
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        eventId,
        remindAt,
        status,
        channel,
        createdAt,
        updatedAt,
        taskTitle,
        eventTitle,
        taskStatus,
      ];
}

class ReminderSnapshot extends Equatable {
  const ReminderSnapshot({
    required this.items,
    this.isFromCache = false,
  });

  final List<Reminder> items;
  final bool isFromCache;

  int get scheduledCount =>
      items.where((reminder) => reminder.isScheduled).length;

  @override
  List<Object?> get props => [items, isFromCache];
}
