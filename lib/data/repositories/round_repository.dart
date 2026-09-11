import 'package:flag_admin_web/data/services/round_service.dart';
import 'package:flag_admin_web/domain/enums/round_type.dart';
import 'package:flag_admin_web/domain/models/round.dart';

/// Repositório de Rodadas (ADR-001 - Cache TTL 30s).
class RoundRepository {
  final RoundService _service;

  RoundRepository({required RoundService service}) : _service = service;

  final Map<String, List<Round>> _cacheByComp = {};
  final Map<String, DateTime> _lastFetchByComp = {};
  static const Duration _cacheTtl = Duration(seconds: 30);

  Future<List<Round>> getRoundsByCompetition(
    String competitionId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cacheByComp[competitionId];
    final lastFetch = _lastFetchByComp[competitionId];
    final isCacheValid =
        cached != null &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return cached;
    }

    final data = await _service.listByCompetition(competitionId);
    _cacheByComp[competitionId] = List<Round>.unmodifiable(data);
    _lastFetchByComp[competitionId] = DateTime.now();
    return _cacheByComp[competitionId]!;
  }

  Future<Round> createRound({
    required String competitionId,
    required int number,
    required String name,
    required RoundType type,
  }) async {
    final created = await _service.create(
      competitionId: competitionId,
      number: number,
      name: name,
      type: type,
    );
    clearCache(competitionId);
    return created;
  }

  Future<Round> updateRound(
    String id, {
    required String competitionId,
    required int number,
    required String name,
    required RoundType type,
  }) async {
    final updated = await _service.update(
      id,
      competitionId: competitionId,
      number: number,
      name: name,
      type: type,
    );
    clearCache(competitionId);
    return updated;
  }

  void clearCache(String competitionId) {
    _cacheByComp.remove(competitionId);
    _lastFetchByComp.remove(competitionId);
  }
}
