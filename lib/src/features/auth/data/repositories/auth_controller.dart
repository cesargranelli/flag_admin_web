import 'package:flag_admin_web/src/api/api.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/features/auth/data/services/firebase_auth_service.dart';
import 'package:flutter/foundation.dart';

/// Estado de autenticação do Admin Web.
class AuthState {
  /// `true` enquanto a sessão persistida está sendo restaurada no boot
  /// (issue #429) — evita o flash de login para usuários com token.
  final bool restoring;
  final bool authenticated;
  final User? user;

  const AuthState({
    this.restoring = false,
    this.authenticated = false,
    this.user,
  });
}

/// Controla a sessão do organizador: login, restauração e logout.
///
/// Fluxo de login:
/// 1. Autentica com Firebase Auth (e-mail/senha)
/// 2. Obtém ID Token do Firebase
/// 3. Chama `GET /api/v1/auth/me` (backend valida Firebase ID Token + lookup PostgreSQL)
/// 4. Persiste dados de sessão Firebase para restauração futura
class AuthController extends ChangeNotifier {
  final SessionManager _session;
  final AuthApi _api;
  final FirebaseAuthService _firebaseAuth;

  AuthState _state = const AuthState(restoring: true);

  AuthState get state => _state;

  AuthController({
    required SessionManager session,
    required AuthApi api,
    required FirebaseAuthService firebaseAuth,
  })  : _session = session,
        _api = api,
        _firebaseAuth = firebaseAuth;

  /// Restaura a sessão ao iniciar:
  /// 1. Se há usuário Firebase (authStateChanges), usa o ID Token e busca `/auth/me`
  /// 2. Senão, tenta token JWT legado (compatibilidade com sessão anterior)
  Future<void> restore() async {
    try {
      // 1. Tenta restaurar via Firebase (caminho principal)
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _restoreFromFirebase();
        return;
      }

      // 2. Fallback: tenta token JWT legado persistido
      final token = await _session.getToken();
      if (token == null) {
        _set(const AuthState());
        return;
      }
      final user = await _api.me();
      _set(AuthState(authenticated: true, user: user));
    } catch (_) {
      try {
        await _session.clear();
      } catch (_) {
        // Ignora falha de limpeza do storage.
      }
      _set(const AuthState());
    }
  }

  Future<void> _restoreFromFirebase() async {
    try {
      final user = await _api.me();
      _set(AuthState(authenticated: true, user: user));
    } catch (_) {
      // Se falhar, faz logout Firebase para evitar estado inconsistente
      await _firebaseAuth.signOut();
      await _session.clear();
      _set(const AuthState());
    }
  }

  /// Autentica com e-mail/senha via Firebase Auth.
  ///
  /// Após login, obtém o ID Token e busca dados do usuário via `/auth/me`.
  /// O ID Token é enviado automaticamente pelo interceptor Dio em chamadas
  /// subsequentes.
  Future<void> login({
    required String email,
    required String password,
    bool keepConnected = false,
  }) async {
    // 1. Autentica no Firebase
    final credential = await _firebaseAuth.signInWithEmailPassword(
      email: email,
      password: password,
    );

    // 2. Garante que temos um ID Token disponível
    await credential.user?.getIdToken(true);

    // 3. Busca dados completos do usuário via API (que envia ID Token)
    final user = await _api.me();

    // 4. Persiste dados de sessão para restauração futura
    await _session.saveFirebaseSession(
      firebaseUid: credential.user!.uid,
      email: email,
      roles: [user.role.toJson()],
      userName: user.name,
    );
    await _session.saveKeepConnected(keepConnected);

    _set(AuthState(authenticated: true, user: user));
  }

  /// Encerra a sessão: faz logout Firebase e limpa storage local.
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      // Ignora falha de logout Firebase.
    }
    try {
      await _session.clear();
    } catch (_) {
      // Ignora falha de limpeza do storage.
    }
    _set(const AuthState());
  }

  void _set(AuthState next) {
    _state = next;
    notifyListeners();
  }
}
