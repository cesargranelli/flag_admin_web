import 'package:flag_admin_web/config/domain_imports.dart';

import '../api_client.dart';

/// Serviço REST de times.
class TeamApi {
  final ApiClient _client;

  TeamApi(this._client);

  /// Lista os times de uma competição (endpoint público).
  Future<List<Team>> listByCompetition(String competitionId) => _client.getList(
    '/api/v1/competitions/$competitionId/teams',
    Team.fromJson,
  );

  Future<Team> getById(String id) =>
      _client.getOne('/api/v1/teams/$id', Team.fromJson);

  /// Criar um time.
  ///
  /// O backend espera `POST /api/v1/teams` com corpo completo
  /// (`clubId` e `competitionId` obrigatórios).
  Future<Team> create({
    required String clubId,
    required String competitionId,
    String? divisionId,
    required String name,
    String? shortName,
    String? document,
    DocumentType? documentType,
    String? logoUrl,
  }) => _client.post('/api/v1/teams', {
    'clubId': clubId,
    'competitionId': competitionId,
    'divisionId': ?divisionId,
    'name': name,
    'shortName': ?shortName,
    'document': ?document,
    'documentType': documentType?.toJson(),
    'logoUrl': ?logoUrl,
  }, Team.fromJson);

  /// Associa um clube (agremiação) a uma competição, criando o time
  /// automaticamente com o nome do clube (rota própria de associação, #377).
  Future<Team> associateClub({
    required String competitionId,
    required String clubId,
  }) => _client.post('/api/v1/competitions/$competitionId/clubs', {
    'clubId': clubId,
  }, Team.fromJson);

  /// Atualiza um time enviando o MESMO corpo completo da criação
  /// (o backend exige `clubId` com `@NotNull`).
  Future<Team> update(
    String id, {
    required String clubId,
    required String competitionId,
    String? divisionId,
    required String name,
    String? shortName,
    String? document,
    DocumentType? documentType,
    String? logoUrl,
  }) => _client.put('/api/v1/teams/$id', {
    'clubId': clubId,
    'competitionId': competitionId,
    'divisionId': ?divisionId,
    'name': name,
    'shortName': ?shortName,
    'document': ?document,
    'documentType': documentType?.toJson(),
    'logoUrl': ?logoUrl,
  }, Team.fromJson);

  /// Remove a inscrição do clube na competição (desassociar).
  Future<void> delete(String id) => _client.delete('/api/v1/teams/$id');

  /// Lista os times esportivos pertencentes a uma agremiação/clube.
  Future<List<Team>> listByOrganization(String clubId) => _client
      .getList('/api/v1/institutions/$clubId/teams', Team.fromJson);

  /// Cria um time dentro de uma agremiação/clube.
  Future<Team> createForOrganization({
    required String clubId,
    required String name,
    String? shortName,
    String? sportName,
    String? logoUrl,
  }) => _client.post('/api/v1/institutions/$clubId/teams', {
    'name': name,
    if (shortName != null && shortName.isNotEmpty) 'shortName': shortName,
    if (sportName != null && sportName.isNotEmpty) 'sportName': sportName,
    if (logoUrl != null && logoUrl.isNotEmpty) 'logoUrl': logoUrl,
  }, Team.fromJson);

  /// Desativação lógica de um time.
  Future<void> deactivate(String id) =>
      _client.post('/api/v1/teams/$id/deactivate', {}, (json) => json);

  /// Reativação de um time.
  Future<void> reactivate(String id) =>
      _client.post('/api/v1/teams/$id/reactivate', {}, (json) => json);
}
