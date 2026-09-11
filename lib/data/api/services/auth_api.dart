import 'package:flag_admin_web/config/domain_imports.dart';

import '../api_client.dart';

/// Serviço REST de autenticação e usuário atual.
class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// Registra novo organizador (status PENDING).
  Future<User> register({required String name, required String email}) =>
      _client.post('/api/v1/auth/register', {
        'name': name,
        'email': email,
      }, User.fromJson);

  Future<User> me() => _client.getOne('/api/v1/auth/me', User.fromJson);

  Future<List<User>> listUsers() =>
      _client.getList('/api/v1/auth/users', User.fromJson);

  Future<User> createUser({
    required String name,
    required String email,
    required String role,
  }) => _client.post('/api/v1/auth/users', {
    'name': name,
    'email': email,
    'role': role,
  }, User.fromJson);

  Future<List<User>> listPendingUsers() =>
      _client.getList('/api/v1/auth/users/pending', User.fromJson);

  Future<User> approveUser(String id) =>
      _client.post('/api/v1/auth/users/$id/approve', {}, User.fromJson);

  Future<User> rejectUser(String id) =>
      _client.post('/api/v1/auth/users/$id/reject', {}, User.fromJson);
}
