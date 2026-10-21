import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/api_exception.dart';
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
    try {
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
    } on DioException catch (error) {
      final apiException = ApiException.fromDioException(error);
      if (apiException.isNetworkError && status == null) {
        final cached = _readCachedReminders();
        if (cached != null) return cached;
      }
      throw apiException;
    }
  }

  Future<Reminder> createReminder({
    String? taskId,
    String? eventId,
    required DateTime remindAt,
  }) {
    return _guard(() async {
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
    return _guard(() async {
      final response = await _remoteDataSource.updateReminder(
        id,
        remindAt: remindAt,
        status: status?.apiValue,
      );
      return Reminder.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<void> deleteReminder(String id) {
    return _guard(() => _remoteDataSource.deleteReminder(id));
  }

  ReminderSnapshot? _readCachedReminders() {
    final json = _cache.readJson(_cacheKey);
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

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
