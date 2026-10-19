import 'user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Global authentication state driving router redirects.
class AuthState {
  const AuthState({required this.status, this.user});

  const AuthState.unknown() : status = AuthStatus.unknown, user = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null;

  const AuthState.authenticated(User this.user)
      : status = AuthStatus.authenticated;

  final AuthStatus status;
  final User? user;
}
