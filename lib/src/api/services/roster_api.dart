import 'package:flag_admin_web/src/domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de elencos (roster) de times.
class RosterApi {
  final ApiClient _client;

  RosterApi(this._client);

  /// Lista as entradas de um elenco.
  Future<List<RosterEntry>> listEntries(String rosterId) => _client.getList(
        '/api/v1/rosters/$rosterId/entries',
        RosterEntry.fromJson,
      );

  /// Adiciona um atleta ao elenco.
  Future<void> add(
    String rosterId, {
    required String athleteId,
    String? nickname,
    int? number,
  }) =>
      _client.post(
        '/api/v1/rosters/$rosterId/entries',
        {
          'athleteId': athleteId,
          'nickname': ?nickname,
          'number': ?number,
        },
        (json) => json,
      );

  /// Remove um atleta do elenco.
  Future<void> remove(String rosterId, String athleteId) =>
      _client.delete('/api/v1/rosters/$rosterId/entries/$athleteId');

  /// Importa uma carga em lote de atletas no elenco (idempotente).
  Future<RosterBatchResult> createBatch(
    String rosterId,
    List<Map<String, dynamic>> athletes,
  ) =>
      _client.post(
        '/api/v1/rosters/$rosterId/entries/batch',
        {'athletes': athletes},
        RosterBatchResult.fromJson,
      );
}
