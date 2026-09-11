import 'package:flag_admin_web/data/api/api_client.dart';
import 'package:flag_admin_web/domain/models/affiliation.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import 'package:flag_admin_web/domain/models/team.dart';

/// Serviço REST de agremiações (camada Services - ADR-001).
abstract class InstitutionService {
  factory InstitutionService(ApiClient client) = ApiInstitutionService;

  Future<List<Institution>> getInstitutions();
  Future<Institution> getInstitution(String id);
  Future<Institution> createInstitution(Map<String, dynamic> body);
  Future<Institution> updateInstitution(String id, Map<String, dynamic> body);
  Future<void> deleteInstitution(String id);
  Future<void> updateOrganizations(String id, List<String> orgIds);
  Future<List<Affiliation>> getAffiliations(String institutionId);
  Future<Affiliation> requestAffiliation(String institutionId, String organizationId, String season);
  Future<List<Team>> getTeams(String institutionId);
  Future<Team> createTeam(String institutionId, Map<String, dynamic> body);
  Future<void> deleteTeam(String teamId);
  Future<void> deactivateTeam(String teamId);
  Future<void> reactivateTeam(String teamId);
}

/// Implementação padrão consumindo [ApiClient].
class ApiInstitutionService implements InstitutionService {
  final ApiClient _client;

  ApiInstitutionService(this._client);

  @override
  Future<List<Institution>> getInstitutions() =>
      _client.getList('/api/v1/institutions', Institution.fromJson);

  @override
  Future<Institution> getInstitution(String id) =>
      _client.getOne('/api/v1/institutions/$id', Institution.fromJson);

  @override
  Future<Institution> createInstitution(Map<String, dynamic> body) =>
      _client.post('/api/v1/institutions', body, Institution.fromJson);

  @override
  Future<Institution> updateInstitution(String id, Map<String, dynamic> body) =>
      _client.put('/api/v1/institutions/$id', body, Institution.fromJson);

  @override
  Future<void> deleteInstitution(String id) =>
      _client.delete('/api/v1/institutions/$id');

  @override
  Future<void> updateOrganizations(String id, List<String> orgIds) =>
      _client.put(
        '/api/v1/institutions/$id/organizations',
        {'organizationIds': orgIds},
        (json) => json,
      );

  @override
  Future<List<Affiliation>> getAffiliations(String institutionId) =>
      _client.getList(
        '/api/v1/institutions/$institutionId/affiliations',
        Affiliation.fromJson,
      );

  @override
  Future<Affiliation> requestAffiliation(
    String institutionId,
    String organizationId,
    String season,
  ) =>
      _client.post(
        '/api/v1/institutions/$institutionId/affiliations',
        {'organizationId': organizationId, 'season': season},
        Affiliation.fromJson,
      );

  @override
  Future<List<Team>> getTeams(String institutionId) =>
      _client.getList(
        '/api/v1/institutions/$institutionId/teams',
        Team.fromJson,
      );

  @override
  Future<Team> createTeam(String institutionId, Map<String, dynamic> body) =>
      _client.post(
        '/api/v1/institutions/$institutionId/teams',
        body,
        Team.fromJson,
      );

  @override
  Future<void> deleteTeam(String teamId) =>
      _client.delete('/api/v1/teams/$teamId');

  @override
  Future<void> deactivateTeam(String teamId) =>
      _client.post('/api/v1/teams/$teamId/deactivate', {}, (json) => json);

  @override
  Future<void> reactivateTeam(String teamId) =>
      _client.post('/api/v1/teams/$teamId/reactivate', {}, (json) => json);
}

