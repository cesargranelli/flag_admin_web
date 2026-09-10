import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/domain/models/roster_entry.dart';
import 'package:flag_admin_web/domain/models/roster_batch.dart';

/// Serviço REST de elencos (roster) de times (camada Services - ADR-001).
abstract class RosterService {
  factory RosterService(ApiClient client) = ApiRosterService;

  Future<List<RosterEntry>> listByTeam(String teamId);
  Future<void> add({
    required String teamId,
    required String athleteId,
    String? nickname,
    int? number,
  });
  Future<void> remove({
    required String teamId,
    required String athleteId,
  });
  Future<RosterBatchResult> createBatch(
    String teamId,
    List<Map<String, dynamic>> athletes,
  );
}

/// Implementação padrão consumindo [ApiClient].
class ApiRosterService implements RosterService {
  final ApiClient _client;

  ApiRosterService(this._client);

  @override
  Future<List<RosterEntry>> listByTeam(String teamId) => _client.getList(
        '/api/v1/teams/$teamId/roster',
        RosterEntry.fromJson,
      );

  @override
  Future<void> add({
    required String teamId,
    required String athleteId,
    String? nickname,
    int? number,
  }) =>
      _client.post(
        '/api/v1/teams/$teamId/roster',
        {
          'athleteId': athleteId,
          'nickname': ?nickname,
          'number': ?number,
        },
        (json) => json,
      );

  @override
  Future<void> remove({
    required String teamId,
    required String athleteId,
  }) =>
      _client.delete('/api/v1/teams/$teamId/roster/$athleteId');

  @override
  Future<RosterBatchResult> createBatch(
    String teamId,
    List<Map<String, dynamic>> athletes,
  ) =>
      _client.post(
        '/api/v1/teams/$teamId/roster/batch',
        {'athletes': athletes},
        RosterBatchResult.fromJson,
      );
}
