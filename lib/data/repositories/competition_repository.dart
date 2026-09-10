import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/models/enrollment_window.dart';
import '../services/competition_service.dart';

/// Repository de competições (camada Repositories - ADR-001).
///
/// Single Source of Truth para campeonatos e torneios.
class CompetitionRepository {
  final CompetitionService _service;

  CompetitionRepository({required CompetitionService service})
      : _service = service;

  List<Competition>? _cache;
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(seconds: 30);

  /// Retorna a lista de competições com suporte a cache em memória com TTL de 30s.
  Future<List<Competition>> getCompetitions({
    bool includeDisabled = false,
    bool forceRefresh = false,
  }) async {
    final isCacheValid = _cache != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return _cache!;
    }
    final data =
        await _service.getCompetitions(includeDisabled: includeDisabled);
    _cache = List<Competition>.unmodifiable(data);
    _lastFetch = DateTime.now();
    return _cache!;
  }

  /// Busca uma competição por ID.
  Future<Competition> getCompetition(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      final match = _cache!.where((c) => c.id == id);
      if (match.isNotEmpty) return match.first;
    }
    return _service.getCompetition(id);
  }

  /// Cria nova competição e invalida o cache.
  Future<Competition> createCompetition(Map<String, dynamic> body) async {
    final created = await _service.createCompetition(body);
    clearCache();
    return created;
  }

  /// Atualiza competição existente e invalida o cache.
  Future<Competition> updateCompetition(
    String id,
    Map<String, dynamic> body,
  ) async {
    final updated = await _service.updateCompetition(id, body);
    clearCache();
    return updated;
  }

  /// Desativa competição e invalida o cache.
  Future<void> deactivateCompetition(String id) async {
    await _service.deactivateCompetition(id);
    clearCache();
  }

  /// Reativa competição e invalida o cache.
  Future<void> reactivateCompetition(String id) async {
    await _service.reactivateCompetition(id);
    clearCache();
  }

  /// Retorna a janela de inscrição de uma competição.
  Future<EnrollmentWindow> getEnrollmentWindow(String competitionId) =>
      _service.getEnrollmentWindow(competitionId);

  /// Retorna todas as janelas de inscrição abertas no momento.
  Future<List<EnrollmentWindow>> getOpenEnrollmentWindows() =>
      _service.getOpenEnrollmentWindows();

  /// Abre ou atualiza a janela de inscrição de uma competição.
  Future<EnrollmentWindow> openEnrollmentWindow(
    String competitionId,
    Map<String, dynamic> body,
  ) async {
    final res = await _service.openEnrollmentWindow(competitionId, body);
    clearCache();
    return res;
  }

  /// Encerra a janela de inscrição de uma competição.
  Future<EnrollmentWindow> closeEnrollmentWindow(String competitionId) async {
    final res = await _service.closeEnrollmentWindow(competitionId);
    clearCache();
    return res;
  }

  /// Invalida o cache em memória.
  void clearCache() {
    _cache = null;
    _lastFetch = null;
  }
}
