import 'package:flag_admin_web/data/services/auth_service.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

/// Repositório de Usuários (ADR-001 - Cache TTL 30s).
class UserRepository {
  final AuthService _service;

  UserRepository({required AuthService service}) : _service = service;

  Future<List<User>> listUsers() async {
    return _service.listUsers();
  }

  Future<User> createUser({
    required String name,
    required String email,
    required String role,
  }) async {
    return _service.createUser(name: name, email: email, role: role);
  }
}
