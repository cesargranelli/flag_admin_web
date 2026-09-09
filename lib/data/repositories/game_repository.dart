import 'package:flag_admin_web/data/services/game_service.dart';
import 'package:flag_admin_web/domain/models/game.dart';

/// Repositório de Jogos (ADR-001 - Cache TTL 30s).
class GameRepository {
  final GameService _service;

  GameRepository({required GameService service}) : _service = service;

  final Map<String, List<Game>> _cacheByComp = {};
  final Map<String, DateTime> _lastFetchByComp = {};
  static const Duration _cacheTtl = Duration(seconds: 30);

  Future<List<Game>> getGamesByCompetition(
    String competitionId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cacheByComp[competitionId];
    final lastFetch = _lastFetchByComp[competitionId];
    final isCacheValid = cached != null &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return cached;
    }

    final data = await _service.listByCompetition(competitionId);
    _cacheByComp[competitionId] = List<Game>.unmodifiable(data);
    _lastFetchByComp[competitionId] = DateTime.now();
    return _cacheByComp[competitionId]!;
  }

  Future<Game> createGame({
    required String competitionId,
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) async {
    final created = await _service.create(
      roundId: roundId,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      venueId: venueId,
      scheduledAt: scheduledAt,
    );
    clearCache(competitionId);
    return created;
  }

  Future<Game> updateGame(
    String id, {
    required String competitionId,
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) async {
    final updated = await _service.update(
      id,
      roundId: roundId,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      venueId: venueId,
      scheduledAt: scheduledAt,
    );
    clearCache(competitionId);
    return updated;
  }

  Future<Game> updateStatus(
    String id, {
    required String competitionId,
    required GameStatus status,
  }) async {
    final updated = await _service.updateStatus(id, status);
    clearCache(competitionId);
    return updated;
  }

  void clearCache(String competitionId) {
    _cacheByComp.remove(competitionId);
    _lastFetchByComp.remove(competitionId);
  }
}
