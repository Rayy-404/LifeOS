import 'package:equatable/equatable.dart';

/// Public user profile returned by `/api/v1/auth/*` (`03-technical-spec.md` Section 4.1).
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.timezone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      timezone: (json['timezone'] as String?) ?? 'Asia/Jakarta',
    );
  }

  final String id;
  final String name;
  final String email;
  final String timezone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'timezone': timezone,
      };

  @override
  List<Object?> get props => [id, name, email, timezone];
}
