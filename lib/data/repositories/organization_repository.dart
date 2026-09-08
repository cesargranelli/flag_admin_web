import 'package:flag_admin_web/domain/models/affiliation.dart';
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
  final Map<bool, DateTime> _lastFetch = {};
  static const Duration _cacheTtl = Duration(seconds: 30);

  /// Retorna as organizações com suporte a cache em memória e TTL de 30s.
  /// Se [forceRefresh] for falso e houver cache válido recente, retorna do cache.
  Future<List<Organization>> getOrganizations({
    bool forceRefresh = false,
    bool includeDisabled = false,
  }) async {
    final isCacheValid = _cache.containsKey(includeDisabled) &&
        _lastFetch.containsKey(includeDisabled) &&
        DateTime.now().difference(_lastFetch[includeDisabled]!) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return _cache[includeDisabled]!;
    }

    try {
      final organizations = await _service.getOrganizations(
        includeDisabled: includeDisabled,
      );
      _cache[includeDisabled] = List<Organization>.unmodifiable(organizations);
      _lastFetch[includeDisabled] = DateTime.now();
      return organizations;
    } catch (_) {
      rethrow;
    }
  }

  /// Busca organização por id. Se presente no cache e não for forceRefresh,
  /// retorna imediatamente; caso contrário, busca via service.
  Future<Organization> getOrganization(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      for (final list in _cache.values) {
        final match = list.where((o) => o.id == id);
        if (match.isNotEmpty) return match.first;
      }
    }
    return _service.getOrganization(id);
  }

  /// Cria uma nova organização e invalida o cache.
  Future<Organization> createOrganization(Map<String, dynamic> body) async {
    final created = await _service.createOrganization(body);
    clearCache();
    return created;
  }

  /// Atualiza uma organização existente e invalida o cache.
  Future<Organization> updateOrganization(String id, Map<String, dynamic> body) async {
    final updated = await _service.updateOrganization(id, body);
    clearCache();
    return updated;
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

  /// Retorna os pedidos de filiação recebidos pela organização.
  Future<List<Affiliation>> getAffiliations(
    String organizationId, {
    String? season,
    String? status,
  }) =>
      _service.getAffiliations(organizationId, season: season, status: status);

  /// Aprova um pedido de filiação de uma agremiação.
  Future<Affiliation> approveAffiliation(String organizationId, String affiliationId) async {
    final res = await _service.approveAffiliation(organizationId, affiliationId);
    clearCache();
    return res;
  }

  /// Rejeita um pedido de filiação de uma agremiação.
  Future<Affiliation> rejectAffiliation(
    String organizationId,
    String affiliationId,
    String reason,
  ) async {
    final res = await _service.rejectAffiliation(organizationId, affiliationId, reason);
    clearCache();
    return res;
  }

  /// Retorna as janelas de filiação cadastradas por uma organização.
  Future<List<AffiliationWindow>> getAffiliationWindows(String organizationId) =>
      _service.getAffiliationWindows(organizationId);

  /// Retorna todas as janelas de filiação abertas no momento em qualquer organização.
  Future<List<AffiliationWindow>> getOpenAffiliationWindows() =>
      _service.getOpenAffiliationWindows();

  /// Abre ou atualiza um período de filiação.
  Future<AffiliationWindow> openAffiliationWindow(
    String organizationId,
    Map<String, dynamic> body,
  ) async {
    final res = await _service.openAffiliationWindow(organizationId, body);
    clearCache();
    return res;
  }

  /// Encerra um período de filiação para uma temporada.
  Future<AffiliationWindow> closeAffiliationWindow(
    String organizationId,
    String season,
  ) async {
    final res = await _service.closeAffiliationWindow(organizationId, season);
    clearCache();
    return res;
  }

  /// Limpa o cache local em memória.
  void clearCache() {
    _cache.clear();
    _lastFetch.clear();
  }
}
