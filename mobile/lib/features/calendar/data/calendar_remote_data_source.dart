import 'package:dio/dio.dart';

/// Raw HTTP access to `/api/v1/calendar/events` endpoints (`03-technical-spec.md` Section 4.4).
class CalendarRemoteDataSource {
  CalendarRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> listAgenda({
    required String from,
    required String to,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/calendar/events',
      queryParameters: {
        'from': from,
        'to': to,
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/calendar/events',
      data: {
        'title': title,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (location != null && location.trim().isNotEmpty)
          'location': location.trim(),
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getEvent(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/calendar/events/$id');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateEvent(
    String id, {
    String? title,
    String? description,
    bool includeNullDescription = false,
    String? location,
    bool includeNullLocation = false,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final payload = <String, dynamic>{
      'title': ?title,
      if (description != null)
        'description': description
      else if (includeNullDescription)
        'description': null,
      if (location != null)
        'location': location
      else if (includeNullLocation)
        'location': null,
      if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
      if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
    };

    final response = await _dio.patch<Map<String, dynamic>>(
      '/calendar/events/$id',
      data: payload,
    );
    return response.data ?? const {};
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete<void>('/calendar/events/$id');
  }
}
