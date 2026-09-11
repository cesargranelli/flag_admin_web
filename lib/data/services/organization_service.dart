import 'package:flag_admin_web/domain/models/affiliation.dart';
import 'package:flag_admin_web/data/api/api_client.dart';
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
  Future<List<Affiliation>> getAffiliations(String organizationId, {String? season, String? status});
  Future<Affiliation> approveAffiliation(String organizationId, String affiliationId);
  Future<Affiliation> rejectAffiliation(String organizationId, String affiliationId, String reason);
  Future<List<AffiliationWindow>> getAffiliationWindows(String organizationId);
  Future<List<AffiliationWindow>> getOpenAffiliationWindows();
  Future<AffiliationWindow> openAffiliationWindow(String organizationId, Map<String, dynamic> body);
  Future<AffiliationWindow> closeAffiliationWindow(String organizationId, String season);
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

  @override
  Future<List<Affiliation>> getAffiliations(
    String organizationId, {
    String? season,
    String? status,
  }) {
    final params = <String>[];
    if (season != null) params.add('season=$season');
    if (status != null) params.add('status=$status');
    final qs = params.isEmpty ? '' : '?${params.join('&')}';
    return _client.getList(
      '/api/v1/organizations/$organizationId/affiliations$qs',
      Affiliation.fromJson,
    );
  }

  @override
  Future<Affiliation> approveAffiliation(String organizationId, String affiliationId) =>
      _client.post(
        '/api/v1/organizations/$organizationId/affiliations/$affiliationId/approve',
        <String, dynamic>{},
        Affiliation.fromJson,
      );

  @override
  Future<Affiliation> rejectAffiliation(
    String organizationId,
    String affiliationId,
    String reason,
  ) =>
      _client.post(
        '/api/v1/organizations/$organizationId/affiliations/$affiliationId/reject',
        {'reason': reason},
        Affiliation.fromJson,
      );

  @override
  Future<List<AffiliationWindow>> getAffiliationWindows(String organizationId) =>
      _client.getList(
        '/api/v1/organizations/$organizationId/affiliation-windows',
        AffiliationWindow.fromJson,
      );

  @override
  Future<List<AffiliationWindow>> getOpenAffiliationWindows() =>
      _client.getList(
        '/api/v1/affiliation-windows/open',
        AffiliationWindow.fromJson,
      );

  @override
  Future<AffiliationWindow> openAffiliationWindow(
    String organizationId,
    Map<String, dynamic> body,
  ) =>
      _client.post(
        '/api/v1/organizations/$organizationId/affiliation-windows',
        body,
        AffiliationWindow.fromJson,
      );

  @override
  Future<AffiliationWindow> closeAffiliationWindow(
    String organizationId,
    String season,
  ) =>
      _client.post(
        '/api/v1/organizations/$organizationId/affiliation-windows/$season/close',
        <String, dynamic>{},
        AffiliationWindow.fromJson,
      );
}

