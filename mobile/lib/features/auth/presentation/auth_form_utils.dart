import '../../../core/errors/api_exception.dart';

/// Client-side validators shared by the Login (S-02) and Register (S-03) forms.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Email wajib diisi';
  }
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(email)) {
    return 'Format email tidak valid';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Password wajib diisi';
  }
  if (password.length < 8) {
    return 'Password minimal 8 karakter';
  }
  return null;
}

String? validateRequiredName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nama wajib diisi';
  }
  return null;
}

/// Maps API errors to human-friendly messages for snackbars.
String humanizeAuthError(ApiException error) {
  if (error.isNetworkError) {
    return error.message;
  }
  switch (error.statusCode) {
    case 401:
      return 'Email atau password salah.';
    case 409:
      return 'Email sudah terdaftar.';
    case 429:
      return 'Terlalu banyak percobaan. Coba lagi sebentar lagi.';
    default:
      return error.message;
  }
}

/// Extracts the first per-field validation message from the API `details` map.
String? fieldError(ApiException error, String field) {
  final messages = error.details[field];
  if (messages == null || messages.isEmpty) {
    return null;
  }
  return messages.first;
}
