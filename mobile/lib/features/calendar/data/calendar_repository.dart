import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_call_guard.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../tasks/domain/task.dart';
import '../domain/calendar_event.dart';
import 'calendar_remote_data_source.dart';

final calendarRemoteDataSourceProvider = Provider<CalendarRemoteDataSource>(
  (ref) => CalendarRemoteDataSource(ref.watch(dioProvider)),
);

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepository(
    remoteDataSource: ref.watch(calendarRemoteDataSourceProvider),
    cache: ref.watch(localCacheServiceProvider),
    notifications: ref.watch(localNotificationServiceProvider),
  ),
);

/// Orchestrates Calendar CRUD, combined agenda query, local read caching (`04-architecture-security-testing.md` §12.1),
/// and local notification cleanup on event delete.
class CalendarRepository {
  CalendarRepository({
    required this._remoteDataSource,
    required this._cache,
    required this._notifications,
  });

  final CalendarRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;
  final LocalNotificationService _notifications;

  static const String _cacheKey = 'calendar_snapshot';

  Future<CalendarAgendaSnapshot> listAgenda({
    required String from,
    required String to,
  }) async {
    try {
      final response = await _remoteDataSource.listAgenda(
        from: from,
        to: to,
      );
      final data =
          (response['data'] as Map<String, dynamic>?) ?? const {};
      final rawEvents = (data['events'] as List<dynamic>?) ?? const [];
      final rawTasks = (data['tasks'] as List<dynamic>?) ?? const [];

      final events = rawEvents
          .whereType<Map<String, dynamic>>()
          .map(CalendarEvent.fromJson)
          .toList();
      final tasks = rawTasks
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();

      await _cache.writeJson(_cacheKey, {
        'from': from,
        'to': to,
        'events': events.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      });

      return CalendarAgendaSnapshot(
        from: from,
        to: to,
        events: events,
        tasks: tasks,
      );
    } on DioException catch (error) {
      final apiException = ApiException.fromDioException(error);
      if (apiException.isNetworkError) {
        final cached = await _readCachedAgenda();
        if (cached != null) {
          return cached;
        }
      }
      throw apiException;
    }
  }

  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startsAt,
    required DateTime endsAt,
  }) {
    return guardApiCall(() async {
      final response = await _remoteDataSource.createEvent(
        title: title,
        description: description,
        location: location,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      return CalendarEvent.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<CalendarEvent> getEvent(String id) {
    return guardApiCall(() async {
      final response = await _remoteDataSource.getEvent(id);
      return CalendarEvent.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<CalendarEvent> updateEvent(
    String id, {
    String? title,
    String? description,
    bool includeNullDescription = false,
    String? location,
    bool includeNullLocation = false,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return guardApiCall(() async {
      final response = await _remoteDataSource.updateEvent(
        id,
        title: title,
        description: description,
        includeNullDescription: includeNullDescription,
        location: location,
        includeNullLocation: includeNullLocation,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      return CalendarEvent.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<void> deleteEvent(
    String id, {
    List<String> reminderIdsToCancel = const [],
  }) {
    return guardApiCall(() async {
      for (final reminderId in reminderIdsToCancel) {
        await _notifications.cancelReminder(reminderId);
      }
      await _remoteDataSource.deleteEvent(id);
    });
  }

  Future<CalendarAgendaSnapshot?> _readCachedAgenda() async {
    final json = await _cache.readJson(_cacheKey);
    if (json == null) return null;
    try {
      final rawEvents = (json['events'] as List<dynamic>?) ?? const [];
      final rawTasks = (json['tasks'] as List<dynamic>?) ?? const [];
      return CalendarAgendaSnapshot(
        from: (json['from'] as String?) ?? '',
        to: (json['to'] as String?) ?? '',
        events: rawEvents
            .whereType<Map<String, dynamic>>()
            .map(CalendarEvent.fromJson)
            .toList(),
        tasks: rawTasks
            .whereType<Map<String, dynamic>>()
            .map(Task.fromJson)
            .toList(),
        isFromCache: true,
      );
    } catch (_) {
      return null;
    }
  }
}
