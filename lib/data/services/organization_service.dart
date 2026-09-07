import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// Serviço REST de organizações (camada Services).
///
/// Responsável exclusivamente pelas chamadas HTTP/REST de organizações.
/// Camada mais baixa, stateless e desacoplada da UI.
abstract class OrganizationService {
  factory OrganizationService(ApiClient client) = ApiOrganizationService;

  Future<List<Organization>> getOrganizations({bool includeDisabled = false});
  Future<Organization> getOrganization(String id);
  Future<Organization> createOrganization(Map<String, dynamic> body);
  Future<Organization> updateOrganization(String id, Map<String, dynamic> body);
  Future<void> deleteOrganization(String id);
  Future<void> reactivateOrganization(String id);
}

/// Implementação padrão consumindo [ApiClient].
class ApiOrganizationService implements OrganizationService {
  final ApiClient _client;

  ApiOrganizationService(this._client);

  @override
  Future<List<Organization>> getOrganizations({bool includeDisabled = false}) =>
      _client.getList(
        '/api/v1/organizations?includeDisabled=$includeDisabled',
        Organization.fromJson,
      );

  @override
  Future<Organization> getOrganization(String id) =>
      _client.getOne('/api/v1/organizations/$id', Organization.fromJson);

  @override
  Future<Organization> createOrganization(Map<String, dynamic> body) async {
    final id = await _client.post<String>(
      '/api/v1/organizations',
      body,
      (json) => json['id'] as String,
    );
    return getOrganization(id);
  }

  @override
  Future<Organization> updateOrganization(String id, Map<String, dynamic> body) =>
      _client.put('/api/v1/organizations/$id', body, Organization.fromJson);

  @override
  Future<void> deleteOrganization(String id) =>
      _client.delete('/api/v1/organizations/$id');

  @override
  Future<void> reactivateOrganization(String id) =>
      _client.post(
        '/api/v1/organizations/$id/reactivate',
        <String, dynamic>{},
        (json) => json,
      );
}
