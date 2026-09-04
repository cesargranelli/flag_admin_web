import '../datasources/venue_firestore_service.dart';

/// Repository para venues.
///
/// Abstrai a fonte de dados (Firestore) da lógica de negócio.
class VenueRepository {
  final VenueFirestoreService _datasource;

  VenueRepository(this._datasource);

  /// Lista todos os venues.
  Future<List<Venue>> getAll() async {
    return await _datasource.list();
  }

  /// Busca venue por ID.
  Future<Venue?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Cria novo venue.
  Future<Venue> create(Venue venue) async {
    return await _datasource.create(venue);
  }

  /// Atualiza venue existente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _datasource.update(id, data);
  }

  /// Remove venue.
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }

  /// Escuta mudanças em tempo real.
  Stream<List<Venue>> watchAll() {
    return _datasource.streamList();
  }
}