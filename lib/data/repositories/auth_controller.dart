import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/domain/models/auth_user.dart';
import 'package:flag_admin_web/domain/models/user.dart';

/// Estado de autenticação do Admin Web (compatibilidade com AppRouter).
class AuthState {
  final bool restoring;
  final bool authenticated;
  final User? user;
  final AuthUser? authUser;

  const AuthState({
    this.restoring = false,
    this.authenticated = false,
    this.user,
    this.authUser,
  });
}

/// Controlador de autenticação para o roteamento e gerenciamento global de sessão.
class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  AuthState _state = const AuthState(restoring: true);
  AuthState get state => _state;

  AuthController({required AuthRepository repository})
    : _repository = repository;

  /// Restaura a sessão ao inicializar a aplicação.
  Future<void> restore() async {
    try {
      final authUser = await _repository.restoreSession();
      if (authUser != null) {
        _state = AuthState(
          restoring: false,
          authenticated: true,
          user: authUser.toLegacyUser(),
          authUser: authUser,
        );
      } else {
        _state = const AuthState(restoring: false, authenticated: false);
      }
    } catch (_) {
      _state = const AuthState(restoring: false, authenticated: false);
    }
    notifyListeners();
  }

  /// Sincroniza o estado a partir do repositório (após login via LoginViewModel).
  void syncFromRepository() {
    final authUser = _repository.currentUser;
    if (authUser != null) {
      _state = AuthState(
        restoring: false,
        authenticated: true,
        user: authUser.toLegacyUser(),
        authUser: authUser,
      );
    } else {
      _state = const AuthState(restoring: false, authenticated: false);
    }
    notifyListeners();
  }

  /// Login direto (compatibilidade).
  Future<void> login({
    required String email,
    required String password,
    bool keepConnected = false,
  }) async {
    final authUser = await _repository.login(
      email: email,
      password: password,
      keepConnected: keepConnected,
    );
    _state = AuthState(
      restoring: false,
      authenticated: true,
      user: authUser.toLegacyUser(),
      authUser: authUser,
    );
    notifyListeners();
  }

  /// Encerra a sessão.
  Future<void> logout() async {
    await _repository.logout();
    _state = const AuthState(restoring: false, authenticated: false);
    notifyListeners();
  }
}
