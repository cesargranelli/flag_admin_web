import '../datasources/season_firestore_service.dart';

/// Repository para temporadas.
///
/// Abstrai a fonte de dados (Firestore) da lógica de negócio.
class SeasonRepository {
  final SeasonFirestoreService _datasource;

  SeasonRepository(this._datasource);

  /// Lista todas as temporadas.
  Future<List<Season>> getAll() async {
    return await _datasource.list();
  }

  /// Busca temporada por ID.
  Future<Season?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Cria nova temporada.
  Future<Season> create(Season season) async {
    return await _datasource.create(season);
  }

  /// Atualiza temporada existente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _datasource.update(id, data);
  }

  /// Remove temporada.
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }

  /// Escuta mudanças em tempo real.
  Stream<List<Season>> watchAll() {
    return _datasource.streamList();
  }

  /// Lista temporadas por organização.
  Future<List<Season>> getByOrganization(String organizationId) {
    return _datasource.listByOrganization(organizationId);
  }

  /// Escuta temporadas por organização.
  Stream<List<Season>> watchByOrganization(String organizationId) {
    return _datasource.streamWhere('organizationId', organizationId);
  }
}