import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/state/data_revision_provider.dart';
import '../data/reminders_repository.dart';
import '../domain/reminder.dart';

class ReminderScheduleResult {
  const ReminderScheduleResult({
    this.reminder,
    required this.permissionGranted,
  });

  final Reminder? reminder;
  final bool permissionGranted;
}

/// Read-only Android notification permission probe used by banners.
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  return ref.watch(localNotificationServiceProvider).areNotificationsEnabled();
});

final remindersControllerProvider =
    AsyncNotifierProvider<RemindersController, ReminderSnapshot>(
  RemindersController.new,
);

/// Owns reminder CRUD plus Android local-notification synchronization
/// (`03-technical-spec.md` §3.2 & `04-architecture-security-testing.md` §12.3).
class RemindersController extends AsyncNotifier<ReminderSnapshot> {
  RemindersRepository get _repository =>
      ref.read(remindersRepositoryProvider);
  LocalNotificationService get _notifications =>
      ref.read(localNotificationServiceProvider);

  @override
  Future<ReminderSnapshot> build() async {
    ref.watch(dataRevisionProvider);
    return _repository.listReminders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.listReminders());
  }

  /// Creates a reminder (permission prompt first), then schedules the alarm.
  /// If notifications are denied the row is persisted as `FAILED`
  /// (edge case §8 no.1).
  Future<ReminderScheduleResult> createReminder({
    String? taskId,
    String? eventId,
    required String title,
    required String body,
    required DateTime remindAt,
  }) async {
    final granted = await _notifications.requestPermissions();

    var reminder = await _repository.createReminder(
      taskId: taskId,
      eventId: eventId,
      remindAt: remindAt,
    );

    if (granted) {
      await _notifications.scheduleReminder(
        reminderUuid: reminder.id,
        title: title,
        body: body,
        remindAt: reminder.remindAt,
      );
    } else {
      reminder = await _repository.updateReminder(
        reminder.id,
        status: ReminderStatus.failed,
      );
    }

    ref.invalidateSelf();
    return ReminderScheduleResult(
      reminder: reminder,
      permissionGranted: granted,
    );
  }

  /// Moves an existing SCHEDULED reminder to a new time, cancelling the old
  /// local alarm and re-arming it with the same deterministic ID.
  Future<ReminderScheduleResult> updateTime(
    Reminder reminder, {
    required DateTime remindAt,
    required String title,
    required String body,
  }) async {
    final updated = await _repository.updateReminder(
      reminder.id,
      remindAt: remindAt,
    );
    await _notifications.cancelReminder(reminder.id);

    final granted = await _notifications.areNotificationsEnabled();
    if (granted) {
      await _notifications.scheduleReminder(
        reminderUuid: updated.id,
        title: title,
        body: body,
        remindAt: updated.remindAt,
      );
    } else {
      final failed = await _repository.updateReminder(
        updated.id,
        status: ReminderStatus.failed,
      );
      ref.invalidateSelf();
      return ReminderScheduleResult(
        reminder: failed,
        permissionGranted: false,
      );
    }

    ref.invalidateSelf();
    return ReminderScheduleResult(
      reminder: updated,
      permissionGranted: true,
    );
  }

  Future<void> cancelReminder(Reminder reminder) async {
    await _repository.updateReminder(
      reminder.id,
      status: ReminderStatus.cancelled,
    );
    await _notifications.cancelReminder(reminder.id);
    ref.invalidateSelf();
  }

  Future<void> deleteReminder(Reminder reminder) async {
    await _repository.deleteReminder(reminder.id);
    await _notifications.cancelReminder(reminder.id);
    ref.invalidateSelf();
  }

  /// Creates or moves the reminder associated with a task/event form.
  Future<ReminderScheduleResult?> upsertForTask({
    required String taskId,
    required String title,
    required DateTime remindAt,
  }) async {
    final scheduled = await _repository.listReminders(
      status: ReminderStatus.scheduled,
    );
    final existing = scheduled.items
        .where((reminder) => reminder.taskId == taskId)
        .firstOrNull;

    if (existing != null) {
      return updateTime(
        existing,
        remindAt: remindAt,
        title: title,
        body: 'Task deadline is approaching',
      );
    }
    return createReminder(
      taskId: taskId,
      title: title,
      body: 'Task deadline is approaching',
      remindAt: remindAt,
    );
  }

  Future<ReminderScheduleResult?> upsertForEvent({
    required String eventId,
    required String title,
    required DateTime remindAt,
  }) async {
    final scheduled = await _repository.listReminders(
      status: ReminderStatus.scheduled,
    );
    final existing = scheduled.items
        .where((reminder) => reminder.eventId == eventId)
        .firstOrNull;

    if (existing != null) {
      return updateTime(
        existing,
        remindAt: remindAt,
        title: title,
        body: 'Your event is coming up',
      );
    }
    return createReminder(
      eventId: eventId,
      title: title,
      body: 'Your event is coming up',
      remindAt: remindAt,
    );
  }

  /// Cancels any scheduled reminders attached to a task/event (used when the
  /// "Remind me" toggle is turned off while editing).
  Future<void> cancelScheduledForTarget({
    String? taskId,
    String? eventId,
  }) async {
    final scheduled = await _repository.listReminders(
      status: ReminderStatus.scheduled,
    );
    for (final reminder in scheduled.items) {
      final matches = taskId != null
          ? reminder.taskId == taskId
          : reminder.eventId == eventId;
      if (!matches) continue;
      await _repository.updateReminder(
        reminder.id,
        status: ReminderStatus.cancelled,
      );
      await _notifications.cancelReminder(reminder.id);
    }
    ref.invalidateSelf();
  }

  /// Startup / resume reconciliation (`03-technical-spec.md` §3.2 item 5):
  /// - cancels orphan local alarms,
  /// - marks overdue SCHEDULED rows `SENT` (permission on) or `FAILED` (off),
  /// - re-arms future alarms missing after a reboot.
  Future<void> syncPendingReminders() async {
    final server = await _repository.listReminders(
      status: ReminderStatus.scheduled,
    );
    final pending = await _notifications.getPendingReminders();
    final pendingIds = pending.map((item) => item.id).toSet();
    final permissionGranted = await _notifications.areNotificationsEnabled();
    final now = DateTime.now();
    var changed = false;

    final serverIds = <int>{};
    for (final reminder in server.items) {
      serverIds.add(
        LocalNotificationService.notificationIdFromUuid(reminder.id),
      );

      if (!reminder.remindAt.isAfter(now)) {
        await _notifications.cancelReminder(reminder.id);
        await _repository.updateReminder(
          reminder.id,
          status: permissionGranted
              ? ReminderStatus.sent
              : ReminderStatus.failed,
        );
        changed = true;
        continue;
      }

      final notificationId =
          LocalNotificationService.notificationIdFromUuid(reminder.id);
      if (!pendingIds.contains(notificationId)) {
        if (permissionGranted) {
          await _notifications.scheduleReminder(
            reminderUuid: reminder.id,
            title: reminder.targetTitle,
            body: reminder.isTaskReminder
                ? 'Task deadline is approaching'
                : 'Your event is coming up',
            remindAt: reminder.remindAt,
          );
        }
      }
    }

    for (final notificationId in pendingIds) {
      if (!serverIds.contains(notificationId)) {
        await _notifications.cancelById(notificationId);
      }
    }

    if (changed) {
      ref.invalidateSelf();
    }
  }
}
