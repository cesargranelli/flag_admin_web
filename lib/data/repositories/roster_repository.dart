import 'package:flag_admin_web/domain/models/roster_entry.dart';
import 'package:flag_admin_web/domain/models/roster_batch.dart';
import '../services/roster_service.dart';

/// Repository de elencos (camada Repositories - ADR-001).
///
/// Cache em memória por teamId com TTL 30s.
class RosterRepository {
  final RosterService _service;

  RosterRepository({required RosterService service})
      : _service = service;

  final Map<String, List<RosterEntry>> _cache = {};
  final Map<String, DateTime> _lastFetch = {};
  static const Duration _cacheTtl = Duration(seconds: 30);

  /// Retorna o elenco de um time com cache TTL 30s.
  Future<List<RosterEntry>> getRoster(
    String teamId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cache[teamId];
    final lastFetch = _lastFetch[teamId];
    final isCacheValid = cached != null &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return cached;
    }

    final data = await _service.listByTeam(teamId);
    _cache[teamId] = List<RosterEntry>.unmodifiable(data);
    _lastFetch[teamId] = DateTime.now();
    return _cache[teamId]!;
  }

  /// Adiciona um atleta ao elenco e invalida o cache do time.
  Future<void> addAthlete({
    required String teamId,
    required String athleteId,
    String? nickname,
    int? number,
  }) async {
    await _service.add(
      teamId: teamId,
      athleteId: athleteId,
      nickname: nickname,
      number: number,
    );
    _cache.remove(teamId);
    _lastFetch.remove(teamId);
  }

  /// Remove um atleta do elenco e invalida o cache do time.
  Future<void> removeAthlete({
    required String teamId,
    required String athleteId,
  }) async {
    await _service.remove(teamId: teamId, athleteId: athleteId);
    _cache.remove(teamId);
    _lastFetch.remove(teamId);
  }

  /// Importa atletas em lote no elenco e invalida o cache.
  Future<RosterBatchResult> createBatch(
    String teamId,
    List<Map<String, dynamic>> athletes,
  ) async {
    final result = await _service.createBatch(teamId, athletes);
    _cache.remove(teamId);
    _lastFetch.remove(teamId);
    return result;
  }

  /// Limpa o cache de um time específico.
  void clearCacheForTeam(String teamId) {
    _cache.remove(teamId);
    _lastFetch.remove(teamId);
  }

  /// Limpa todo o cache.
  void clearCache() {
    _cache.clear();
    _lastFetch.clear();
  }
}
