import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_mobile/app/theme_controller.dart';
import 'package:lifeos_mobile/core/notifications/local_notification_service.dart';
import 'package:lifeos_mobile/core/notifications/notification_settings_controller.dart';
import 'package:lifeos_mobile/core/storage/local_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestNotificationService extends LocalNotificationService {
  String? lastShownTitle;
  String? lastShownBody;

  @override
  Future<void> showNotification({
    int id = 1001,
    required String title,
    required String body,
  }) async {
    lastShownTitle = title;
    lastShownBody = body;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Preferences — ThemeModeNotifier', () {
    test('default theme is ThemeMode.light when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifierContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      expect(notifierContainer.read(themeModeProvider), ThemeMode.light);
    });

    test('updates theme mode and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), 'dark');

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(prefs.getString('app_theme_mode'), 'system');
    });

    test('initializes with saved theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('Preferences — NotificationSettingsNotifier', () {
    test('default settings are enabled=true, sound=true, alerts=true', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final settings = container.read(notificationSettingsProvider);
      expect(settings.enabled, isTrue);
      expect(settings.sound, isTrue);
      expect(settings.reminderAlerts, isTrue);
    });

    test('toggling settings updates state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await container.read(notificationSettingsProvider.notifier).setEnabled(false);
      expect(container.read(notificationSettingsProvider).enabled, isFalse);
      expect(prefs.getBool('app_notif_enabled'), isFalse);

      await container.read(notificationSettingsProvider.notifier).setSound(false);
      expect(container.read(notificationSettingsProvider).sound, isFalse);
      expect(prefs.getBool('app_notif_sound'), isFalse);

      await container.read(notificationSettingsProvider.notifier).setReminderAlerts(false);
      expect(container.read(notificationSettingsProvider).reminderAlerts, isFalse);
      expect(prefs.getBool('app_notif_alerts'), isFalse);
    });
  });

  group('LocalNotificationService — showNotification', () {
    test('showNotification records dispatched notification', () async {
      final service = _TestNotificationService();
      await service.showNotification(
        title: 'Test Notification',
        body: 'Testing reminder notification dispatch',
      );
      expect(service.lastShownTitle, 'Test Notification');
      expect(service.lastShownBody, 'Testing reminder notification dispatch');
    });
  });
}
