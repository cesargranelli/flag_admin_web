import '../datasources/organization_firestore_service.dart';

/// Repository para organizações.
///
/// Abstrai a fonte de dados (Firestore) da lógica de negócio.
class OrganizationRepository {
  final OrganizationFirestoreService _datasource;

  OrganizationRepository(this._datasource);

  /// Lista todas as organizações.
  Future<List<Organization>> getAll() async {
    return await _datasource.list();
  }

  /// Busca organização por ID.
  Future<Organization?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Cria nova organização.
  Future<Organization> create(Organization organization) async {
    return await _datasource.create(organization);
  }

  /// Atualiza organização existente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _datasource.update(id, data);
  }

  /// Remove organização.
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }

  /// Escuta mudanças em tempo real.
  Stream<List<Organization>> watchAll() {
    return _datasource.streamList();
  }
}
