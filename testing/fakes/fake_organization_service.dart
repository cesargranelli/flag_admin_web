import 'package:flag_admin_web/data/services/organization_service.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// Fake in-memory implementation of [OrganizationService] for tests.
class FakeOrganizationService implements OrganizationService {
  final List<Organization> organizations;
  bool shouldThrow = false;
  String? errorMessage;
  int getOrganizationsCallCount = 0;
  int deleteCallCount = 0;
  int reactivateCallCount = 0;

  FakeOrganizationService({List<Organization>? initial})
      : organizations = initial != null ? List.from(initial) : [];

  @override
  Future<List<Organization>> getOrganizations({
    bool includeDisabled = false,
  }) async {
    getOrganizationsCallCount++;
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro de rede simulado');
    }
    if (includeDisabled) {
      return List.from(organizations);
    }
    return organizations
        .where((o) => o.status != OrganizationStatus.inactive)
        .toList();
  }

  @override
  Future<Organization> getOrganization(String id) async {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao buscar organização');
    }
    final match = organizations.where((o) => o.id == id);
    if (match.isEmpty) {
      throw Exception('Organização não encontrada: $id');
    }
    return match.first;
  }

  @override
  Future<Organization> createOrganization(Map<String, dynamic> body) async {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao criar organização');
    }
    final org = Organization.fromJson({
      'id': 'org-${organizations.length + 1}',
      ...body,
    });
    organizations.add(org);
    return org;
  }

  @override
  Future<void> deleteOrganization(String id) async {
    deleteCallCount++;
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao desativar organização');
    }
    final index = organizations.indexWhere((o) => o.id == id);
    if (index != -1) {
      final existing = organizations[index];
      final json = existing.toJson();
      json['id'] = existing.id;
      json['status'] = 'INACTIVE';
      organizations[index] = Organization.fromJson(json);
    }
  }

  @override
  Future<void> reactivateOrganization(String id) async {
    reactivateCallCount++;
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Erro ao reativar organização');
    }
    final index = organizations.indexWhere((o) => o.id == id);
    if (index != -1) {
      final existing = organizations[index];
      final json = existing.toJson();
      json['id'] = existing.id;
      json['status'] = 'ACTIVE';
      organizations[index] = Organization.fromJson(json);
    }
  }
}

Organization createTestOrganization({
  String id = 'org-1',
  String tradeName = 'Org Teste',
  String legalName = 'Org Teste Ltda',
  OrganizationType type = OrganizationType.federation,
  OrganizationStatus status = OrganizationStatus.active,
}) {
  return Organization(
    id: id,
    tradeName: tradeName,
    legalName: legalName,
    country: 'BR',
    timezone: 'America/Sao_Paulo',
    locale: 'pt-BR',
    organizationType: type,
    status: status,
  );
}
