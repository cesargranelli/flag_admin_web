import 'package:flag_admin_web/domain/models/affiliation.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import 'package:flag_admin_web/domain/models/team.dart';
import '../services/institution_service.dart';

/// Repository de agremiações (camada Repositories - ADR-001).
///
/// Single Source of Truth para clubes e universidades.
class InstitutionRepository {
  final InstitutionService _service;

  InstitutionRepository({required InstitutionService service})
      : _service = service;

  List<Institution>? _cache;
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(seconds: 30);

  final Map<String, List<Team>> _teamsCache = {};
  final Map<String, DateTime> _teamsLastFetch = {};

  /// Retorna a lista de agremiações com suporte a cache em memória com TTL de 30s.
  Future<List<Institution>> getInstitutions({bool forceRefresh = false}) async {
    final isCacheValid = _cache != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return _cache!;
    }
    final data = await _service.getInstitutions();
    _cache = List<Institution>.unmodifiable(data);
    _lastFetch = DateTime.now();
    return _cache!;
  }

  /// Busca uma agremiação por ID.
  Future<Institution> getInstitution(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      final match = _cache!.where((i) => i.id == id);
      if (match.isNotEmpty) return match.first;
    }
    return _service.getInstitution(id);
  }

  /// Cria nova agremiação e invalida o cache.
  Future<Institution> createInstitution(Map<String, dynamic> body) async {
    final created = await _service.createInstitution(body);
    clearCache();
    return created;
  }

  /// Atualiza agremiação existente e invalida o cache.
  Future<Institution> updateInstitution(
    String id,
    Map<String, dynamic> body,
  ) async {
    final updated = await _service.updateInstitution(id, body);
    clearCache();
    return updated;
  }

  /// Exclui agremiação e invalida o cache.
  Future<void> deleteInstitution(String id) async {
    await _service.deleteInstitution(id);
    clearCache();
  }

  /// Atualiza a filiação a organizações (N:N) e invalida o cache.
  Future<void> updateOrganizations(String id, List<String> orgIds) async {
    await _service.updateOrganizations(id, orgIds);
    clearCache();
  }

  /// Busca as equipes esportivas da agremiação com cache TTL 30s.
  Future<List<Team>> getTeams(String institutionId, {bool forceRefresh = false}) async {
    final cached = _teamsCache[institutionId];
    final lastFetch = _teamsLastFetch[institutionId];
    final isCacheValid = cached != null &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return cached;
    }

    final data = await _service.getTeams(institutionId);
    _teamsCache[institutionId] = List<Team>.unmodifiable(data);
    _teamsLastFetch[institutionId] = DateTime.now();
    return _teamsCache[institutionId]!;
  }

  /// Cria uma nova equipe na agremiação e invalida o cache de times.
  Future<Team> createTeam({
    required String institutionId,
    required String name,
    String? shortName,
    String? sportName,
    String? logoUrl,
  }) async {
    final body = {
      'name': name,
      if (shortName != null && shortName.isNotEmpty) 'shortName': shortName,
      if (sportName != null && sportName.isNotEmpty) 'sportName': sportName,
      if (logoUrl != null && logoUrl.isNotEmpty) 'logoUrl': logoUrl,
    };
    final created = await _service.createTeam(institutionId, body);
    _teamsCache.remove(institutionId);
    _teamsLastFetch.remove(institutionId);
    return created;
  }

  /// Exclui um time e invalida o cache.
  Future<void> deleteTeam(String institutionId, String teamId) async {
    await _service.deleteTeam(teamId);
    _teamsCache.remove(institutionId);
    _teamsLastFetch.remove(institutionId);
  }

  /// Desativa um time logicamente.
  Future<void> deactivateTeam(String institutionId, String teamId) async {
    await _service.deactivateTeam(teamId);
    _teamsCache.remove(institutionId);
    _teamsLastFetch.remove(institutionId);
  }

  /// Reativa um time desativado logicamente.
  Future<void> reactivateTeam(String institutionId, String teamId) async {
    await _service.reactivateTeam(teamId);
    _teamsCache.remove(institutionId);
    _teamsLastFetch.remove(institutionId);
  }

  /// Retorna as filiações da agremiação.
  Future<List<Affiliation>> getAffiliations(
    String institutionId, {
    bool forceRefresh = false,
  }) async {
    return _service.getAffiliations(institutionId);
  }

  /// Solicita nova filiação a uma organização.
  Future<Affiliation> requestAffiliation(
    String institutionId,
    String organizationId,
    String season,
  ) async {
    final created = await _service.requestAffiliation(institutionId, organizationId, season);
    clearCache();
    return created;
  }

  /// Limpa o cache local.
  void clearCache() {
    _cache = null;
    _lastFetch = null;
    _teamsCache.clear();
    _teamsLastFetch.clear();
  }
}

