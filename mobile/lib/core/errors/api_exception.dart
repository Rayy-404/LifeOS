import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Standard API Error matching NestJS Global Exception Filter (`03-technical-spec.md`).
class ApiException extends Equatable implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const {},
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, List<String>> details;

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final rawDetails = data['details'];
      final parsedDetails = <String, List<String>>{};
      if (rawDetails is Map) {
        rawDetails.forEach((key, value) {
          if (value is List) {
            parsedDetails[key.toString()] = value
                .map((item) => item.toString())
                .toList();
          }
        });
      }

      return ApiException(
        statusCode: (data['statusCode'] as int?) ?? response?.statusCode ?? 500,
        code: (data['code'] as String?) ?? 'UNKNOWN_API_ERROR',
        message: (data['message'] as String?) ?? 'Terjadi kesalahan pada server.',
        details: parsedDetails,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }

    return ApiException(
      statusCode: response?.statusCode ?? 500,
      code: 'UNEXPECTED_ERROR',
      message: error.message ?? 'Terjadi kesalahan yang tidak terduga.',
    );
  }

  bool get isNetworkError => statusCode == 0 || code == 'NETWORK_ERROR';
  bool get isUnauthorized => statusCode == 401;

  @override
  List<Object?> get props => [statusCode, code, message, details];

  @override
  String toString() => 'ApiException($statusCode, $code: $message)';
}
