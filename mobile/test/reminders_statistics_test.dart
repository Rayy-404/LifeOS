import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_mobile/core/notifications/local_notification_service.dart';
import 'package:lifeos_mobile/features/calendar/domain/calendar_event.dart';
import 'package:lifeos_mobile/features/reminders/data/reminders_repository.dart';
import 'package:lifeos_mobile/features/reminders/domain/reminder.dart';
import 'package:lifeos_mobile/features/reminders/presentation/reminders_controller.dart';
import 'package:lifeos_mobile/features/statistics/domain/statistics.dart';
import 'package:lifeos_mobile/features/tasks/domain/task.dart';

class _FakeRemindersRepository implements RemindersRepository {
  _FakeRemindersRepository(this.reminders);

  List<Reminder> reminders;
  final List<String> cancelledIds = [];
  final Map<String, ReminderStatus> updatedStatuses = {};

  @override
  Future<ReminderSnapshot> listReminders({ReminderStatus? status}) async {
    return ReminderSnapshot(
      items: status == null
          ? List.of(reminders)
          : reminders.where((item) => item.status == status).toList(),
    );
  }

  @override
  Future<Reminder> createReminder({
    String? taskId,
    String? eventId,
    required DateTime remindAt,
  }) async {
    final reminder = Reminder(
      id: 'created-${reminders.length + 1}',
      taskId: taskId,
      eventId: eventId,
      remindAt: remindAt,
      status: ReminderStatus.scheduled,
      channel: ReminderChannel.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      taskTitle: taskId == null ? null : 'Created task',
      eventTitle: eventId == null ? null : 'Created event',
    );
    reminders.add(reminder);
    return reminder;
  }

  @override
  Future<Reminder> updateReminder(
    String id, {
    DateTime? remindAt,
    ReminderStatus? status,
  }) async {
    final index = reminders.indexWhere((item) => item.id == id);
    final current = reminders[index];
    final updated = Reminder(
      id: current.id,
      taskId: current.taskId,
      eventId: current.eventId,
      remindAt: remindAt ?? current.remindAt,
      status: status ?? current.status,
      channel: current.channel,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      taskTitle: current.taskTitle,
      eventTitle: current.eventTitle,
    );
    reminders[index] = updated;
    if (status != null) updatedStatuses[id] = status;
    return updated;
  }

  @override
  Future<void> deleteReminder(String id) async {
    reminders.removeWhere((item) => item.id == id);
  }
}

class _FakeNotificationService extends LocalNotificationService {
  _FakeNotificationService({
    required this.permissionGranted,
    this.pending = const [],
  });

  final bool permissionGranted;
  List<PendingNotificationRequest> pending;
  final List<String> scheduledUuids = [];
  final List<String> cancelledUuids = [];
  final List<int> cancelledIds = [];

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<bool> requestPermissions() async => permissionGranted;

  @override
  Future<List<PendingNotificationRequest>> getPendingReminders() async =>
      pending;

  @override
  Future<void> scheduleReminder({
    required String reminderUuid,
    required String title,
    required String body,
    required DateTime remindAt,
  }) async {
    scheduledUuids.add(reminderUuid);
  }

  @override
  Future<void> cancelReminder(String reminderUuid) async {
    cancelledUuids.add(reminderUuid);
  }

  @override
  Future<void> cancelById(int notificationId) async {
    cancelledIds.add(notificationId);
  }
}

Reminder _reminder({
  required String id,
  required DateTime remindAt,
  String? taskTitle,
}) {
  return Reminder(
    id: id,
    taskId: 'task-$id',
    remindAt: remindAt,
    status: ReminderStatus.scheduled,
    channel: ReminderChannel.local,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    taskTitle: taskTitle ?? 'Task $id',
  );
}

void main() {
  group('Reminder model', () {
    test('maps status/channel and preserves target summary', () {
      final reminder = Reminder.fromJson({
        'id': 'rem-1',
        'taskId': 'task-1',
        'eventId': null,
        'remindAt': '2026-10-20T08:00:00.000Z',
        'status': 'SCHEDULED',
        'channel': 'LOCAL',
        'createdAt': '2026-10-19T08:00:00.000Z',
        'updatedAt': '2026-10-19T08:00:00.000Z',
        'task': {
          'id': 'task-1',
          'title': 'Makalah Etika Profesi',
          'status': 'TODO',
        },
      });

      expect(reminder.status, ReminderStatus.scheduled);
      expect(reminder.channel, ReminderChannel.local);
      expect(reminder.isTaskReminder, isTrue);
      expect(reminder.targetTitle, 'Makalah Etika Profesi');
      expect(reminder.taskStatus, TaskStatus.todo);

      final roundTrip = Reminder.fromJson(reminder.toJson());
      expect(roundTrip.id, reminder.id);
      expect(roundTrip.status, reminder.status);
      expect(roundTrip.targetTitle, reminder.targetTitle);
    });

    test('snapshot only counts SCHEDULED reminders', () {
      final snapshot = ReminderSnapshot(
        items: [
          _reminder(
            id: 'a',
            remindAt: DateTime.now().add(const Duration(hours: 1)),
          ),
          _reminder(
            id: 'b',
            remindAt: DateTime.now().add(const Duration(hours: 2)),
          ).copyWithForTest(status: ReminderStatus.sent),
          _reminder(
            id: 'c',
            remindAt: DateTime.now().add(const Duration(hours: 3)),
          ).copyWithForTest(status: ReminderStatus.failed),
        ],
      );

      expect(snapshot.scheduledCount, 1);
    });
  });

  group('Reminder reconciliation (startup/resume)', () {
    test('re-arms missing future alarms and cancels orphan notifications', () async {
      final now = DateTime.now();
      final upToDate = _reminder(
        id: 'up-to-date',
        remindAt: now.add(const Duration(hours: 2)),
      );
      final missing = _reminder(
        id: 'missing',
        remindAt: now.add(const Duration(hours: 3)),
      );
      final overdue = _reminder(
        id: 'overdue',
        remindAt: now.subtract(const Duration(hours: 1)),
      );
      final orphanId = 777;

      final repository = _FakeRemindersRepository([
        upToDate,
        missing,
        overdue,
      ]);
      final notifications = _FakeNotificationService(
        permissionGranted: true,
        pending: [
          PendingNotificationRequest(
            LocalNotificationService.notificationIdFromUuid(upToDate.id),
            'Task up-to-date',
            'Task deadline is approaching',
            null,
          ),
          PendingNotificationRequest(
            orphanId,
            'Orphan',
            'Old alarm',
            null,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          remindersRepositoryProvider.overrideWithValue(repository),
          localNotificationServiceProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remindersControllerProvider.future);
      await container
          .read(remindersControllerProvider.notifier)
          .syncPendingReminders();

      expect(
        notifications.scheduledUuids,
        contains(missing.id),
      );
      expect(
        notifications.scheduledUuids,
        isNot(contains(upToDate.id)),
      );
      expect(notifications.cancelledUuids, contains(overdue.id));
      expect(repository.updatedStatuses[overdue.id], ReminderStatus.sent);
      expect(notifications.cancelledIds, contains(orphanId));
    });

    test('marks past reminders FAILED when permission is disabled', () async {
      final now = DateTime.now();
      final overdue = _reminder(
        id: 'overdue-off',
        remindAt: now.subtract(const Duration(minutes: 30)),
      );
      final future = _reminder(
        id: 'future-off',
        remindAt: now.add(const Duration(hours: 1)),
      );

      final repository = _FakeRemindersRepository([overdue, future]);
      final notifications = _FakeNotificationService(
        permissionGranted: false,
      );

      final container = ProviderContainer(
        overrides: [
          remindersRepositoryProvider.overrideWithValue(repository),
          localNotificationServiceProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remindersControllerProvider.future);
      await container
          .read(remindersControllerProvider.notifier)
          .syncPendingReminders();

      expect(repository.updatedStatuses[overdue.id], ReminderStatus.failed);
      expect(notifications.scheduledUuids, isEmpty);
    });
  });

  group('Statistics models', () {
    test('parses overview, weekly points, and computes week delta', () {
      final current = StatisticsOverview.fromJson({
        'from': '2026-10-12',
        'to': '2026-10-18',
        'tasks': {
          'total': 4,
          'completed': 3,
          'overdue': 1,
          'completionRate': 75.0,
        },
        'habits': {
          'totalScheduledInstances': 10,
          'totalCompletedInstances': 4,
          'consistencyRate': 40.0,
        },
      });
      final previous = StatisticsOverview.fromJson({
        'from': '2026-10-05',
        'to': '2026-10-11',
        'tasks': {
          'total': 2,
          'completed': 1,
          'overdue': 0,
          'completionRate': 50.0,
        },
        'habits': {
          'totalScheduledInstances': 7,
          'totalCompletedInstances': 2,
          'consistencyRate': 28.6,
        },
      });
      final weekly = WeeklyStatistics.fromJson({
        'weekStart': '2026-10-12',
        'weekEnd': '2026-10-18',
        'days': [
          {
            'date': '2026-10-12',
            'isoWeekday': 1,
            'tasksCompleted': 2,
            'habitsScheduled': 2,
            'habitsCompleted': 1,
          },
        ],
      });

      final bundle = StatisticsBundle(
        currentWeek: current,
        previousWeek: previous,
        weekly: weekly,
      );

      expect(bundle.currentWeek.tasks.completionRate, 75.0);
      expect(bundle.currentWeek.habits.totalScheduledInstances, 10);
      expect(bundle.completionDelta, 25.0);
      expect(bundle.weekly.days.single.tasksCompleted, 2);

      final roundTrip = StatisticsBundle.fromJson(bundle.toJson());
      expect(roundTrip.currentWeek.tasks.completed, 3);
      expect(roundTrip.weekly.weekEnd, '2026-10-18');
    });
  });

  group('Cache round-trip keeps reminder ids', () {
    test('Task.toJson preserves reminders for offline cancellation', () {
      final task = Task(
        id: 'task-1',
        title: 'Task',
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
        reminderIds: const ['rem-1', 'rem-2'],
      );

      final decoded = Task.fromJson(task.toJson());
      expect(decoded.reminderIds, ['rem-1', 'rem-2']);
    });

    test('CalendarEvent.toJson preserves reminders for offline cancellation', () {
      final event = CalendarEvent(
        id: 'event-1',
        title: 'Event',
        startsAt: DateTime.utc(2026, 10, 1, 8),
        endsAt: DateTime.utc(2026, 10, 1, 9),
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
        reminderIds: const ['rem-3'],
      );

      final decoded = CalendarEvent.fromJson(event.toJson());
      expect(decoded.reminderIds, ['rem-3']);
    });
  });
}

extension on Reminder {
  Reminder copyWithForTest({ReminderStatus? status}) {
    return Reminder(
      id: id,
      taskId: taskId,
      eventId: eventId,
      remindAt: remindAt,
      status: status ?? this.status,
      channel: channel,
      createdAt: createdAt,
      updatedAt: updatedAt,
      taskTitle: taskTitle,
      eventTitle: eventTitle,
      taskStatus: taskStatus,
    );
  }
}
