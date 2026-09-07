import 'auth_user.dart';

/// Estado de sessão do usuário no Admin Web (ADR-001).
class AuthSession {
  final bool isRestoring;
  final bool isAuthenticated;
  final AuthUser? user;
  final String? errorMessage;

  const AuthSession({
    this.isRestoring = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  const AuthSession.restoring()
      : isRestoring = true,
        isAuthenticated = false,
        user = null,
        errorMessage = null;

  const AuthSession.unauthenticated({String? error})
      : isRestoring = false,
        isAuthenticated = false,
        user = null,
        errorMessage = error;

  const AuthSession.authenticated(this.user)
      : isRestoring = false,
        isAuthenticated = true,
        errorMessage = null;

  AuthSession copyWith({
    bool? isRestoring,
    bool? isAuthenticated,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthSession(
      isRestoring: isRestoring ?? this.isRestoring,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}
