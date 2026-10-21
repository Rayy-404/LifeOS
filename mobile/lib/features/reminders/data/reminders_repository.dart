import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_call_guard.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/local_cache_service.dart';
import '../domain/reminder.dart';
import 'reminders_remote_data_source.dart';

final remindersRemoteDataSourceProvider = Provider<RemindersRemoteDataSource>(
  (ref) => RemindersRemoteDataSource(ref.watch(dioProvider)),
);

final remindersRepositoryProvider = Provider<RemindersRepository>(
  (ref) => RemindersRepository(
    remoteDataSource: ref.watch(remindersRemoteDataSourceProvider),
    cache: ref.watch(localCacheServiceProvider),
  ),
);

/// Reminder CRUD with a local read cache for the full reminder list.
class RemindersRepository {
  RemindersRepository({
    required this._remoteDataSource,
    required this._cache,
  });

  final RemindersRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;

  static const String _cacheKey = 'reminders_snapshot';

  Future<ReminderSnapshot> listReminders({ReminderStatus? status}) async {
    return guardApiCallWithCacheFallback<ReminderSnapshot>(
      action: () async {
        final response =
            await _remoteDataSource.listReminders(status: status?.apiValue);
        final rawItems = (response['data'] as List<dynamic>?) ?? const [];
        final items = rawItems
            .whereType<Map<String, dynamic>>()
            .map(Reminder.fromJson)
            .toList();

        final snapshot = ReminderSnapshot(items: items);
        if (status == null) {
          await _cache.writeJson(
            _cacheKey,
            {'data': items.map((item) => item.toJson()).toList()},
          );
        }
        return snapshot;
      },
      // Cache hanya dipakai untuk daftar penuh (tanpa filter status).
      readCache: status == null ? _readCachedReminders : _noCachedReminders,
    );
  }

  Future<Reminder> createReminder({
    String? taskId,
    String? eventId,
    required DateTime remindAt,
  }) {
    return guardApiCall(() async {
      final response = await _remoteDataSource.createReminder(
        taskId: taskId,
        eventId: eventId,
        remindAt: remindAt,
      );
      return Reminder.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<Reminder> updateReminder(
    String id, {
    DateTime? remindAt,
    ReminderStatus? status,
  }) {
    return guardApiCall(() async {
      final response = await _remoteDataSource.updateReminder(
        id,
        remindAt: remindAt,
        status: status?.apiValue,
      );
      return Reminder.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<void> deleteReminder(String id) {
    return guardApiCall(() => _remoteDataSource.deleteReminder(id));
  }

  Future<ReminderSnapshot?> _readCachedReminders() async {
    final json = await _cache.readJson(_cacheKey);
    if (json == null) return null;
    try {
      final rawItems = (json['data'] as List<dynamic>?) ?? const [];
      return ReminderSnapshot(
        items: rawItems
            .whereType<Map<String, dynamic>>()
            .map(Reminder.fromJson)
            .toList(),
        isFromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ReminderSnapshot?> _noCachedReminders() async => null;
}
