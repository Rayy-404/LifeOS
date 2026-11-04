import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_cache_service.dart';

class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.sound = true,
    this.reminderAlerts = true,
  });

  final bool enabled;
  final bool sound;
  final bool reminderAlerts;

  NotificationSettings copyWith({
    bool? enabled,
    bool? sound,
    bool? reminderAlerts,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      reminderAlerts: reminderAlerts ?? this.reminderAlerts,
    );
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const String _keyEnabled = 'app_notif_enabled';
  static const String _keySound = 'app_notif_sound';
  static const String _keyAlerts = 'app_notif_alerts';

  @override
  NotificationSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationSettings(
      enabled: prefs.getBool(_keyEnabled) ?? true,
      sound: prefs.getBool(_keySound) ?? true,
      reminderAlerts: prefs.getBool(_keyAlerts) ?? true,
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyEnabled, value);
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(sound: value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keySound, value);
  }

  Future<void> setReminderAlerts(bool value) async {
    state = state.copyWith(reminderAlerts: value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyAlerts, value);
  }
}
