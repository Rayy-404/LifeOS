import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService(ref.watch(secureStorageServiceProvider));
});

/// Online-First JSON Read Cache (`04-architecture-security-testing.md` Section 12.1).
///
/// Security audit F4: cache payloads are stored in the platform keystore
/// (`flutter_secure_storage`) instead of plain `SharedPreferences`, because
/// they contain user content (task titles, event locations, statistics).
/// `SharedPreferences` is only used for non-sensitive UI flags such as the
/// onboarding marker.
class LocalCacheService {
  LocalCacheService(this._storage);

  final SecureStorageService _storage;

  static const String _prefix = 'lifeos_cache_';

  Future<void> writeJson(String key, Map<String, dynamic> data) async {
    try {
      await _storage.writeValue('$_prefix$key', jsonEncode(data));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    try {
      final raw = await _storage.readValue('$_prefix$key');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAllCache() async {
    try {
      final entries = await _storage.readAll();
      for (final key in entries.keys.where((k) => k.startsWith(_prefix))) {
        await _storage.deleteValue(key);
      }
    } catch (_) {}
  }
}
