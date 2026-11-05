import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_cache_service.dart';
import 'theme.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _key = 'app_theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    final ThemeMode mode;
    switch (saved) {
      case 'dark':
        mode = ThemeMode.dark;
        break;
      case 'system':
        mode = ThemeMode.system;
        break;
      case 'light':
      default:
        mode = ThemeMode.light;
        break;
    }
    final platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    AppColors.isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);
    return mode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    AppColors.isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    String val;
    switch (mode) {
      case ThemeMode.dark:
        val = 'dark';
        break;
      case ThemeMode.system:
        val = 'system';
        break;
      case ThemeMode.light:
        val = 'light';
        break;
    }
    await prefs.setString(_key, val);
  }
}
