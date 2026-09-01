import 'package:flag_admin_web/src/domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de organizações.
class OrganizationApi {
  final ApiClient _client;

  OrganizationApi(this._client);

  Future<List<Organization>> list({bool includeDisabled = false}) =>
      _client.getList(
        '/api/v1/organizations?includeDisabled=$includeDisabled',
        Organization.fromJson,
      );

  Future<Organization> getById(String id) =>
      _client.getOne('/api/v1/organizations/$id', Organization.fromJson);

  /// Exclusão lógica: marca a organização como desativada (INACTIVE).
  Future<void> deactivate(String id) =>
      _client.delete('/api/v1/organizations/$id');

  /// Reativa a organização (exclusivo ADMIN).
  Future<void> reactivate(String id) =>
      _client.post('/api/v1/organizations/$id/reactivate', <String, dynamic>{},
          (json) => json);

  Future<Organization> create(Map<String, dynamic> body) async {
    // POST retorna {id, tradeName, message}: busca o registro completo depois.
    final id = await _client.post<String>(
      '/api/v1/organizations',
      body,
      (json) => json['id'] as String,
    );
    return getById(id);
  }

  /// Clubes/universidades associados a uma federação/liga/associação.
  Future<List<Organization>> listClubs(String organizationId) =>
      _client.getList(
        '/api/v1/organizations/$organizationId/clubs',
        Organization.fromJson,
      );

  /// Associa um clube/universidade à organização (federação/liga/associação).
  Future<Organization> associateClub(
    String organizationId,
    String clubId,
  ) =>
      _client.post(
        '/api/v1/organizations/$organizationId/clubs',
        {'organizationId': clubId},
        Organization.fromJson,
      );

  /// Remove a associação do clube/universidade à organização.
  Future<void> disassociateClub(
    String organizationId,
    String clubId,
  ) =>
      _client.delete(
        '/api/v1/organizations/$organizationId/clubs/$clubId',
      );
}
