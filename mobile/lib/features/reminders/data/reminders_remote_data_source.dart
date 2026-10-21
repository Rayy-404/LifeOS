import 'package:dio/dio.dart';

/// Raw HTTP access to `/api/v1/reminders` (`03-technical-spec.md` Section 4.5).
class RemindersRemoteDataSource {
  RemindersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> listReminders({String? status}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reminders',
      queryParameters: {
        'status': ?status,
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> createReminder({
    String? taskId,
    String? eventId,
    required DateTime remindAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/reminders',
      data: {
        'taskId': ?taskId,
        'eventId': ?eventId,
        'remindAt': remindAt.toUtc().toIso8601String(),
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateReminder(
    String id, {
    DateTime? remindAt,
    String? status,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/reminders/$id',
      data: {
        'remindAt': ?remindAt?.toUtc().toIso8601String(),
        'status': ?status,
      },
    );
    return response.data ?? const {};
  }

  Future<void> deleteReminder(String id) async {
    await _dio.delete<void>('/reminders/$id');
  }
}
