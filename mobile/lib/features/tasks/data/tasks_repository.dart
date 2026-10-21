import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_call_guard.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../domain/task.dart';
import 'tasks_remote_data_source.dart';

final tasksRemoteDataSourceProvider = Provider<TasksRemoteDataSource>(
  (ref) => TasksRemoteDataSource(ref.watch(dioProvider)),
);

final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepository(
    remoteDataSource: ref.watch(tasksRemoteDataSourceProvider),
    cache: ref.watch(localCacheServiceProvider),
    notifications: ref.watch(localNotificationServiceProvider),
  ),
);

/// Orchestrates task CRUD, local read caching (`04-architecture-security-testing.md` Section 12.1),
/// and local notification cancellation when a task is completed or deleted (`FR-TASK-04`).
class TasksRepository {
  TasksRepository({
    required this._remoteDataSource,
    required this._cache,
    required this._notifications,
  });

  final TasksRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;
  final LocalNotificationService _notifications;

  static const String _cacheKey = 'tasks_snapshot';

  Future<PaginatedTasks> listTasks({
    TaskStatus? status,
    TaskPriority? priority,
    String? from,
    String? to,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final isDefaultQuery = status == null &&
        priority == null &&
        from == null &&
        to == null &&
        (search == null || search.trim().isEmpty) &&
        page == 1;

    try {
      final response = await _remoteDataSource.listTasks(
        status: status?.apiValue,
        priority: priority?.apiValue,
        from: from,
        to: to,
        search: search,
        page: page,
        limit: limit,
      );

      final rawItems = (response['data'] as List<dynamic>?) ?? const [];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
      final meta = PaginationMeta.fromJson(
        response['meta'] as Map<String, dynamic>?,
        items.length,
      );

      if (isDefaultQuery) {
        await _cache.writeJson(_cacheKey, {
          'data': items.map((t) => t.toJson()).toList(),
          'meta': meta.toJson(),
        });
      }

      return PaginatedTasks(items: items, meta: meta);
    } on DioException catch (error) {
      final apiException = ApiException.fromDioException(error);
      if (apiException.isNetworkError) {
        final cached = await _readCachedTasks();
        if (cached != null) {
          return cached;
        }
      }
      throw apiException;
    }
  }

  Future<Task> createTask({
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueAt,
  }) {
    return guardApiCall(() async {
      final response = await _remoteDataSource.createTask(
        title: title,
        description: description,
        status: status.apiValue,
        priority: priority.apiValue,
        dueAt: dueAt,
      );
      return Task.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<Task> getTask(String id) {
    return guardApiCall(() async {
      final response = await _remoteDataSource.getTask(id);
      return Task.fromJson(response['data'] as Map<String, dynamic>);
    });
  }

  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    bool includeNullDescription = false,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueAt,
    bool includeNullDueAt = false,
    List<String> reminderIdsToCancelOnDone = const [],
  }) {
    return guardApiCall(() async {
      final response = await _remoteDataSource.updateTask(
        id,
        title: title,
        description: description,
        includeNullDescription: includeNullDescription,
        status: status?.apiValue,
        priority: priority?.apiValue,
        dueAt: dueAt,
        includeNullDueAt: includeNullDueAt,
      );
      final updated = Task.fromJson(response['data'] as Map<String, dynamic>);

      if (updated.isDone && reminderIdsToCancelOnDone.isNotEmpty) {
        for (final reminderId in reminderIdsToCancelOnDone) {
          await _notifications.cancelReminder(reminderId);
        }
      }

      return updated;
    });
  }

  Future<void> deleteTask(
    String id, {
    List<String> reminderIds = const [],
  }) {
    return guardApiCall(() async {
      await _remoteDataSource.deleteTask(id);
      for (final reminderId in reminderIds) {
        await _notifications.cancelReminder(reminderId);
      }
    });
  }

  Future<PaginatedTasks?> _readCachedTasks() async {
    final json = await _cache.readJson(_cacheKey);
    if (json == null) return null;
    try {
      final rawItems = (json['data'] as List<dynamic>?) ?? const [];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
      final meta = PaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>?,
        items.length,
      );
      return PaginatedTasks(
        items: items,
        meta: meta,
        isFromCache: true,
      );
    } catch (_) {
      return null;
    }
  }
}
