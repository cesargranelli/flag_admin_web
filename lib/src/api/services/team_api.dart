import 'package:flag_admin_web/src/domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de times.
class TeamApi {
  final ApiClient _client;

  TeamApi(this._client);

  /// Lista os times de uma organização.
  Future<List<Team>> listByOrganization(String organizationId) =>
      _client.getList(
        '/api/v1/organizations/$organizationId/teams',
        Team.fromJson,
      );

  /// Lista os times inscritos em um campeonato.
  ///
  /// O backend retorna `CompetitionTeamResponse` (inscrição + dados derivados
  /// do time), não `Team` completo.
  Future<List<CompetitionTeam>> listByCompetition(String competitionId) =>
      _client.getList(
        '/api/v1/competitions/$competitionId/teams',
        CompetitionTeam.fromJson,
      );

  /// Lista todos os times cadastrados na plataforma (endpoint público).
  Future<List<Team>> listAll() =>
      _client.getList('/api/v1/teams', Team.fromJson);

  Future<Team> getById(String id) =>
      _client.getOne('/api/v1/teams/$id', Team.fromJson);

  /// Cria um time dentro de uma organização.
  Future<Team> create(
    String organizationId, {
    required String name,
    String? shortName,
    String? logoUrl,
  }) =>
      _client.post('/api/v1/organizations/$organizationId/teams', {
        'name': name,
        'shortName': ?shortName,
        'logoUrl': ?logoUrl,
      }, Team.fromJson);

  /// Atualiza um time.
  Future<Team> update(
    String teamId, {
    required String name,
    String? shortName,
    String? logoUrl,
  }) =>
      _client.put('/api/v1/teams/$teamId', {
        'name': name,
        'shortName': ?shortName,
        'logoUrl': ?logoUrl,
      }, Team.fromJson);

  /// Remove um time.
  Future<void> delete(String teamId) =>
      _client.delete('/api/v1/teams/$teamId');

  /// Desativa um time (status INACTIVE).
  Future<void> deactivate(String teamId) =>
      _client.post('/api/v1/teams/$teamId/deactivate', <String, dynamic>{},
          (json) => json);

  /// Reativa um time (status ACTIVE).
  Future<void> reactivate(String teamId) =>
      _client.post('/api/v1/teams/$teamId/reactivate', <String, dynamic>{},
          (json) => json);

  /// Inscreve um time em uma competição (opcionalmente em uma divisão).
  Future<void> enroll(
    String competitionId,
    String teamId, {
    String? divisionId,
  }) =>
      _client.post(
        '/api/v1/competitions/$competitionId/teams/$teamId',
        {'divisionId': ?divisionId},
        (json) => json,
      );

  /// Remove a inscrição do time na competição.
  Future<void> disenroll(String competitionId, String teamId) =>
      _client.delete(
        '/api/v1/competitions/$competitionId/teams/$teamId',
      );
}
