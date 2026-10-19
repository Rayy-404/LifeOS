import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalCacheService(prefs);
});

/// Online-First JSON Read Cache (`04-architecture-security-testing.md` Section 12.1).
class LocalCacheService {
  LocalCacheService(this._prefs);

  final SharedPreferences _prefs;

  static const String _prefix = 'lifeos_cache_';

  Future<void> writeJson(String key, Map<String, dynamic> data) async {
    await _prefs.setString('$_prefix$key', jsonEncode(data));
  }

  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
