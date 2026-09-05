import 'package:flag_admin_web/src/domain/domain.dart';

import '../datasources/venue_firestore_service.dart';

/// Repository para venues.
///
/// Abstrai a fonte de dados (Firestore — leitura realtime, espelho ADR-006)
/// da lógica de negócio, operando sobre o [Venue] de domínio.
///
/// A escrita NÃO passa por aqui (issue #53): permanece 100% via REST
/// (`venueApiProvider` → POST/PUT/DELETE /api/v1/venues), com o Firestore
/// como espelho gravado pelo backend. Por isso os métodos de escrita Firestore
/// (create/update/delete antes herdados do datasource) foram removidos.
class VenueRepository {
  final VenueFirestoreService _datasource;

  VenueRepository(this._datasource);

  /// Lista todos os venues (sem filtro de status — não existe para venue).
  Future<List<Venue>> getAll() async {
    return await _datasource.list();
  }

  /// Busca venue por ID.
  Future<Venue?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Escuta todos os venues em tempo real (sem filtro de status).
  Stream<List<Venue>> watchAll() {
    return _datasource.streamList();
  }
}