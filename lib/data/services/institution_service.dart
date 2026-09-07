import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/domain/models/institution.dart';

/// Serviço REST de agremiações (camada Services - ADR-001).
abstract class InstitutionService {
  factory InstitutionService(ApiClient client) = ApiInstitutionService;

  Future<List<Institution>> getInstitutions();
  Future<Institution> getInstitution(String id);
  Future<Institution> createInstitution(Map<String, dynamic> body);
  Future<Institution> updateInstitution(String id, Map<String, dynamic> body);
  Future<void> deleteInstitution(String id);
  Future<void> updateOrganizations(String id, List<String> orgIds);
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
}
