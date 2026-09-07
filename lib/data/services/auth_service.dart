import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/src/domain/models/user.dart';

/// Exceção de serviço de autenticação com mensagem amigável em português.
class AuthServiceException implements Exception {
  final String code;
  final String message;

  const AuthServiceException({required this.code, required this.message});

  @override
  String toString() => message;
}

/// Interface de serviço de autenticação (ADR-001).
abstract class AuthService {
  factory AuthService(ApiClient client, {fb.FirebaseAuth? firebaseAuth}) =
      ApiAuthService;

  Stream<fb.User?> get authStateChanges;
  fb.User? get currentFirebaseUser;
  Future<String?> getIdToken({bool forceRefresh = false});

  Future<fb.UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<fb.UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();

  Future<User> registerBackend({
    required String name,
    required String email,
  });

  Future<User> getMe();
  Future<List<User>> listUsers();
  Future<List<User>> listPendingUsers();
  Future<User> approveUser(String id);
  Future<User> rejectUser(String id);
}

/// Implementação padrão integrando Firebase Auth SDK e API REST (backend).
class ApiAuthService implements AuthService {
  final ApiClient _client;
  final fb.FirebaseAuth _firebaseAuth;

  ApiAuthService(
    this._client, {
    fb.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  @override
  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  fb.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  @override
  Future<fb.UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthServiceException(
        code: e.code,
        message: _mapFirebaseError(e.code),
      );
    } catch (e) {
      throw AuthServiceException(
        code: 'unknown',
        message: 'Erro ao autenticar: ',
      );
    }
  }

  @override
  Future<fb.UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthServiceException(
        code: e.code,
        message: _mapFirebaseError(e.code),
      );
    } catch (e) {
      throw AuthServiceException(
        code: 'unknown',
        message: 'Erro ao criar conta: ',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthServiceException(
        code: e.code,
        message: _mapFirebaseError(e.code),
      );
    } catch (e) {
      throw AuthServiceException(
        code: 'unknown',
        message: 'Erro ao enviar e-mail de recuperação: ',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<User> registerBackend({
    required String name,
    required String email,
  }) {
    return _client.post(
      '/api/v1/auth/register',
      {'name': name, 'email': email},
      User.fromJson,
    );
  }

  @override
  Future<User> getMe() {
    return _client.getOne('/api/v1/auth/me', User.fromJson);
  }

  @override
  Future<List<User>> listUsers() {
    return _client.getList('/api/v1/auth/users', User.fromJson);
  }

  @override
  Future<List<User>> listPendingUsers() {
    return _client.getList('/api/v1/auth/users/pending', User.fromJson);
  }

  @override
  Future<User> approveUser(String id) {
    return _client.post('/api/v1/auth/users//approve', {}, User.fromJson);
  }

  @override
  Future<User> rejectUser(String id) {
    return _client.post('/api/v1/auth/users//reject', {}, User.fromJson);
  }

  /// Mapeamento de erros do Firebase Auth para português amigável.
  static String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
        return 'Não existe conta cadastrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Autenticação com e-mail e senha não está habilitada.';
      case 'network-request-failed':
        return 'Falha na conexão de rede. Verifique seu acesso à internet.';
      case 'too-many-requests':
        return 'Muitas tentativas sem sucesso. Tente novamente mais tarde.';
      case 'invalid-credential':
        return 'Credenciais inválidas. Verifique seu e-mail e senha.';
      default:
        return 'Ocorreu um erro na autenticação. Tente novamente.';
    }
  }
}
