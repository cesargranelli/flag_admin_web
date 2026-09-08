import 'package:flag_admin_web/data/services/auth_service.dart';
import 'package:flag_admin_web/domain/models/auth_user.dart';
import 'package:flag_admin_web/src/core/session/session_manager.dart';
import 'package:flag_admin_web/src/domain/models/user.dart';

/// Repositório de Autenticação (ADR-001 / Single Source of Truth).
class AuthRepository {
  final AuthService _service;
  final SessionManager _session;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthRepository({
    required AuthService service,
    required SessionManager session,
  })  : _service = service,
        _session = session;

  /// Restaura a sessão existente ao inicializar a aplicação.
  Future<AuthUser?> restoreSession() async {
    try {
      final fbUser = _service.currentFirebaseUser;
      if (fbUser != null) {
        final token = await _service.getIdToken();
        final user = await _service.getMe();
        _currentUser = AuthUser.fromUser(user, token: token);
        return _currentUser;
      }

      // Fallback legado via SessionManager
      final legacyToken = await _session.getToken();
      if (legacyToken == null) {
        _currentUser = null;
        return null;
      }

      final user = await _service.getMe();
      _currentUser = AuthUser.fromUser(user, token: legacyToken);
      return _currentUser;
    } catch (_) {
      try {
        await _service.signOut();
        await _session.clear();
      } catch (_) {}
      _currentUser = null;
      return null;
    }
  }

  /// Autentica com e-mail e senha via Firebase Auth e sincroniza perfil/token com backend.
  Future<AuthUser> login({
    required String email,
    required String password,
    bool keepConnected = false,
  }) async {
    // 1. Autentica no Firebase Auth (necessário para Firebase Storage e regras cliente)
    final credential = await _service.signInWithEmailPassword(
      email: email,
      password: password,
    );

    // 2. Autentica no backend REST para obter o token JWT do Spring Boot
    String? backendToken;
    User? backendUser;
    try {
      final backendResponse = await _service.loginBackend(
        email: email,
        password: password,
      );
      backendToken = backendResponse.token;
      backendUser = backendResponse.user;
    } catch (_) {
      // Se falhar a chamada direta (ex: usuário recém criado ou formato de senha),
      // tenta recuperar perfil via getMe()
    }

    final user = backendUser ?? await _service.getMe();
    final effectiveToken = backendToken ?? await credential.user?.getIdToken(true);

    final authUser = AuthUser.fromUser(user, token: effectiveToken);
    _currentUser = authUser;

    // Salva o JWT nativo do backend para que o ApiClient utilize em todas as requisições
    if (backendToken != null) {
      await _session.saveSession(
        token: backendToken,
        roles: [user.role.toJson()],
        userName: user.name,
      );
    }

    await _session.saveFirebaseSession(
      firebaseUid: credential.user!.uid,
      email: email,
      roles: [user.role.toJson()],
      userName: user.name,
    );
    await _session.saveKeepConnected(keepConnected);

    return authUser;
  }

  /// Registra um novo organizador (Firebase Auth + backend PostgreSQL status PENDING).
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // 1. Cria credencial no Firebase Auth
    await _service.signUpWithEmailPassword(
      email: email,
      password: password,
    );

    // 2. Faz logout do Firebase imediatamente para que o endpoint de cadastro
    // não envie o token no header
    await _service.signOut();

    // 3. Registra dados do perfil no backend
    await _service.registerBackend(
      name: name,
      email: email,
    );
  }

  /// Envia e-mail para redefinição de senha.
  Future<void> sendPasswordReset(String email) async {
    await _service.sendPasswordResetEmail(email);
  }

  /// Encerra a sessão atual.
  Future<void> logout() async {
    try {
      await _service.signOut();
    } catch (_) {}
    try {
      await _session.clear();
    } catch (_) {}
    _currentUser = null;
  }

  // Métodos de gestão de usuários (administração)
  Future<List<User>> listUsers() => _service.listUsers();
  Future<List<User>> listPendingUsers() => _service.listPendingUsers();
  Future<User> approveUser(String id) => _service.approveUser(id);
  Future<User> rejectUser(String id) => _service.rejectUser(id);
}
