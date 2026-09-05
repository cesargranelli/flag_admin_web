import 'package:firebase_auth/firebase_auth.dart';

/// Erro de autenticação Firebase com mensagem amigável.
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  const FirebaseAuthException({required this.code, required this.message});

  /// Fabrica a exceção a partir de [FirebaseAuthException].
  factory FirebaseAuthException.from(FirebaseAuthException error) {
    return FirebaseAuthException(code: error.code, message: error.message);
  }

  /// Fabrica a exceção a partir de [FirebaseAuthException].
  factory FirebaseAuthException.fromDart(dynamic error) {
    if (error is FirebaseAuthException) {
      return FirebaseAuthException(code: error.code, message: error.message);
    }
    return const FirebaseAuthException(
      code: 'unknown',
      message: 'Erro desconhecido de autenticação',
    );
  }

  @override
  String toString() => 'FirebaseAuthException($code): $message';
}

/// Serviço de autenticação Firebase para o Admin Web.
///
/// Mantém compatibilidade com o backend JWT existente — o ID Token Firebase
/// é enviado no header `Authorization: Bearer <idToken>` nas chamadas REST.
class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Stream do estado de autenticação (User atual ou null).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuário autenticado no momento, ou null.
  User? get currentUser => _auth.currentUser;

  /// ID Token JWT do usuário atual (renovado automaticamente pelo Firebase).
  ///
  /// Retorna null se não houver usuário autenticado. O token é válido para
  /// o backend (via Firebase Admin SDK + lookup no PostgreSQL).
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  /// ID Token com forc refresh (garante token válido para logout).
  Future<String?> getIdTokenResult() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final idTokenResult = await user.getIdTokenResult(true);
    return idTokenResult.token;
  }

  /// Login com e-mail e senha via Firebase Auth.
  ///
  /// Lança [FirebaseAuthException] em caso de falha.
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _friendlyMessage(e.code),
      );
    }
  }

  /// Cadastro com e-mail e senha via Firebase Auth.
  ///
  /// Lança [FirebaseAuthException] em caso de falha.
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _friendlyMessage(e.code),
      );
    }
  }

  /// Logout (limpa sessão Firebase local).
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envia e-mail de redefinição de senha.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _friendlyMessage(e.code),
      );
    }
  }

  /// Mensagem amigável para cada código de erro do Firebase Auth.
  static String _friendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
        return 'Não existe conta com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Login com e-mail/senha não está habilitado.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'invalid-credential':
        return 'Credenciais inválidas. Verifique e-mail e senha.';
      default:
        return 'Erro de autenticação. Tente novamente.';
    }
  }
}
