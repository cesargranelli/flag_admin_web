import '../datasources/team_firestore_service.dart';

/// Repository para times.
///
/// Abstrai a fonte de dados (Firestore) da lógica de negócio.
class TeamRepository {
  final TeamFirestoreService _datasource;

  TeamRepository(this._datasource);

  /// Lista todos os times.
  Future<List<Team>> getAll() async {
    return await _datasource.list();
  }

  /// Busca time por ID.
  Future<Team?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Cria novo time.
  Future<Team> create(Team team) async {
    return await _datasource.create(team);
  }

  /// Atualiza time existente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _datasource.update(id, data);
  }

  /// Remove time.
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }

  /// Escuta mudanças em tempo real.
  Stream<List<Team>> watchAll() {
    return _datasource.streamList();
  }

  /// Lista times por organização.
  Future<List<Team>> getByOrganization(String organizationId) {
    return _datasource.listByOrganization(organizationId);
  }

  /// Escuta times por organização.
  Stream<List<Team>> watchByOrganization(String organizationId) {
    return _datasource.streamWhere('organizationId', organizationId);
  }
}