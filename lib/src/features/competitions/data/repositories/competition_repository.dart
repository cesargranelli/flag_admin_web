import '../datasources/competition_firestore_service.dart';

/// Repository para competições.
///
/// Abstrai a fonte de dados (Firestore) da lógica de negócio.
class CompetitionRepository {
  final CompetitionFirestoreService _datasource;

  CompetitionRepository(this._datasource);

  /// Lista todas as competições.
  Future<List<Competition>> getAll() async {
    return await _datasource.list();
  }

  /// Busca competição por ID.
  Future<Competition?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Cria nova competição.
  Future<Competition> create(Competition competition) async {
    return await _datasource.create(competition);
  }

  /// Atualiza competição existente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _datasource.update(id, data);
  }

  /// Remove competição.
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }

  /// Escuta mudanças em tempo real.
  Stream<List<Competition>> watchAll() {
    return _datasource.streamList();
  }

  /// Lista competições por organização.
  Future<List<Competition>> getByOrganization(String organizationId) {
    return _datasource.listByOrganization(organizationId);
  }

  /// Escuta competições por organização.
  Stream<List<Competition>> watchByOrganization(String organizationId) {
    return _datasource.streamWhere('organizationId', organizationId);
  }

  /// Lista competições por season.
  Future<List<Competition>> getBySeason(String seasonId) {
    return _datasource.listBySeason(seasonId);
  }

  /// Lista competições por status.
  Future<List<Competition>> getByStatus(String status) {
    return _datasource.listByStatus(status);
  }
}