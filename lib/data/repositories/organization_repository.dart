import 'package:flag_admin_web/src/domain/domain.dart';
import '../services/organization_service.dart';

/// Repository de organizações (camada Repositories).
///
/// Atua como Single Source of Truth para o domínio de organizações.
/// Abstrai a fonte de dados (service), provê caching e centraliza
/// políticas de retry e tratamento de exceções.
class OrganizationRepository {
  final OrganizationService _service;

  OrganizationRepository({required OrganizationService service})
      : _service = service;

  // Cache em memória mapeado por flag includeDisabled
  final Map<bool, List<Organization>> _cache = {};

  /// Retorna as organizações.
  /// Se [forceRefresh] for falso e houver cache válido, retorna do cache em memória.
  Future<List<Organization>> getOrganizations({
    bool forceRefresh = false,
    bool includeDisabled = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(includeDisabled)) {
      return _cache[includeDisabled]!;
    }

    try {
      final organizations = await _service.getOrganizations(
        includeDisabled: includeDisabled,
      );
      _cache[includeDisabled] = List<Organization>.unmodifiable(organizations);
      return organizations;
    } catch (_) {
      rethrow;
    }
  }

  /// Busca organização por id. Se presente no cache, retorna imediatamente;
  /// caso contrário, busca via service.
  Future<Organization> getOrganization(String id) async {
    for (final list in _cache.values) {
      final match = list.where((o) => o.id == id);
      if (match.isNotEmpty) return match.first;
    }
    return _service.getOrganization(id);
  }

  /// Cria uma nova organização e invalida o cache.
  Future<Organization> createOrganization(Map<String, dynamic> body) async {
    final created = await _service.createOrganization(body);
    clearCache();
    return created;
  }

  /// Desativa/exclui logicamente a organização e invalida o cache.
  Future<void> deleteOrganization(String id) async {
    await _service.deleteOrganization(id);
    clearCache();
  }

  /// Reativa a organização e invalida o cache.
  Future<void> reactivateOrganization(String id) async {
    await _service.reactivateOrganization(id);
    clearCache();
  }

  /// Limpa o cache local em memória.
  void clearCache() {
    _cache.clear();
  }
}
