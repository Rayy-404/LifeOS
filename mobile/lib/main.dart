import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/storage/local_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  final notificationService = LocalNotificationService();
  try {
    await notificationService.initialize();
  } catch (error) {
    debugPrint('LocalNotificationService initialization warning: $error');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        localNotificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const LifeOSApp(),
    ),
  );
}
