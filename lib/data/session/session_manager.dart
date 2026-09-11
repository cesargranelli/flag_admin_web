import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gerencia a sessão do usuário autenticado.
///
/// Suporta dois modos de autenticação:
/// - **JWT Custom** (legado): token JWT salvo localmente
/// - **Firebase Auth** (novo): Firebase UID persistido para restauração de sessão
///
/// Uso: [Public App] não precisa; [Referee App] e [Admin Web] usam após login.
class SessionManager {
  // JWT Custom (legado)
  static const _tokenKey = 'auth_token';
  static const _rolesKey = 'auth_roles';
  static const _userNameKey = 'auth_user_name';
  static const _keepConnectedKey = 'auth_keep_connected';

  // Firebase Auth (novo)
  static const _firebaseUidKey = 'firebase_uid';
  static const _firebaseEmailKey = 'firebase_email';

  final FlutterSecureStorage _storage;

  SessionManager([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  // === JWT Custom (legado) ===

  Future<void> saveSession({
    required String token,
    required List<String> roles,
    String? userName,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _rolesKey, value: roles.join(','));
    if (userName != null) {
      await _storage.write(key: _userNameKey, value: userName);
    }
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: _rolesKey);
    if (raw == null || raw.isEmpty) return const [];
    return raw.split(',').where((r) => r.isNotEmpty).toList();
  }

  Future<String?> getUserName() => _storage.read(key: _userNameKey);

  Future<bool> isAuthenticated() async => (await getToken()) != null;

  Future<void> saveKeepConnected(bool value) =>
      _storage.write(key: _keepConnectedKey, value: value.toString());

  Future<bool> isKeepConnected() async =>
      (await _storage.read(key: _keepConnectedKey)) == 'true';

  // === Firebase Auth (novo) ===

  /// Salva dados do Firebase para restauração de sessão.
  Future<void> saveFirebaseSession({
    required String firebaseUid,
    required String email,
    required List<String> roles,
    String? userName,
  }) async {
    await _storage.write(key: _firebaseUidKey, value: firebaseUid);
    await _storage.write(key: _firebaseEmailKey, value: email);
    await _storage.write(key: _rolesKey, value: roles.join(','));
    if (userName != null) {
      await _storage.write(key: _userNameKey, value: userName);
    }
  }

  /// Firebase UID do usuário autenticado (para restauração de sessão).
  Future<String?> getFirebaseUid() => _storage.read(key: _firebaseUidKey);

  /// E-mail do usuário Firebase.
  Future<String?> getFirebaseEmail() => _storage.read(key: _firebaseEmailKey);

  /// Limpa toda a sessão (JWT e Firebase).
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _rolesKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _keepConnectedKey);
    await _storage.delete(key: _firebaseUidKey);
    await _storage.delete(key: _firebaseEmailKey);
  }
}
