import 'package:equatable/equatable.dart';
import 'user.dart';

/// Token pair + profile returned by register/login/refresh.
class AuthSession extends Equatable {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  @override
  List<Object?> get props => [user, accessToken, refreshToken, expiresIn];
}
