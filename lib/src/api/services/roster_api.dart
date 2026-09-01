import 'package:flag_admin_web/src/domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de elencos (roster) de times.
///
/// Endpoints reais do backend (ADR-006): o elenco é sempre resolvido por
/// `teamId + competitionId` (não existe mais o conceito de "roster por id"
/// na API pública).
class RosterApi {
  final ApiClient _client;

  RosterApi(this._client);

  /// Lista as entradas do elenco de um time numa competição.
  Future<List<RosterEntry>> listByTeamAndCompetition(
    String teamId,
    String competitionId,
  ) =>
      _client.getList(
        '/api/v1/teams/$teamId/competitions/$competitionId/roster',
        RosterEntry.fromJson,
      );

  /// Lista os elencos (rosters) de um time, independente da competição.
  Future<List<Roster>> listRostersByTeam(String teamId) => _client.getList(
        '/api/v1/teams/$teamId/rosters',
        Roster.fromJson,
      );

  /// Adiciona um atleta ao elenco de um time numa competição.
  Future<void> add(
    String teamId,
    String competitionId, {
    required String athleteId,
    String? nickname,
    int? number,
  }) =>
      _client.post(
        '/api/v1/teams/$teamId/competitions/$competitionId/roster',
        {
          'athleteId': athleteId,
          'nickname': ?nickname,
          'number': ?number,
        },
        (json) => json,
      );

  /// Remove um atleta do elenco de um time numa competição.
  Future<void> remove(
    String teamId,
    String competitionId,
    String athleteId,
  ) =>
      _client.delete(
        '/api/v1/teams/$teamId/competitions/$competitionId/roster/$athleteId',
      );

  /// Importa uma carga em lote de atletas no elenco (idempotente).
  Future<RosterBatchResult> createBatch(
    String teamId,
    String competitionId,
    List<Map<String, dynamic>> athletes,
  ) =>
      _client.post(
        '/api/v1/teams/$teamId/competitions/$competitionId/roster/batch',
        {'athletes': athletes},
        RosterBatchResult.fromJson,
      );
}