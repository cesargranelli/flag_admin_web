import 'package:flag_admin_web/data/api/api_client.dart';
import 'package:flag_admin_web/data/api/services/game_api.dart';
import 'package:flag_admin_web/data/services/game_service.dart';
import 'package:flag_admin_web/domain/enums/game_status.dart';
import 'package:flag_admin_web/domain/models/game.dart';
import 'package:flag_admin_web/domain/models/game_batch.dart';

class ApiGameService implements GameService {
  final GameApi _api;

  ApiGameService(ApiClient client) : _api = GameApi(client);

  @override
  Future<List<Game>> listByCompetition(String competitionId) =>
      _api.listByCompetition(competitionId);

  @override
  Future<List<Game>> listByRound(String roundId) => _api.listByRound(roundId);

  @override
  Future<Game> getById(String id) => _api.getById(id);

  @override
  Future<Game> create({
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) => _api.create(
    roundId: roundId,
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    venueId: venueId,
    scheduledAt: scheduledAt,
  );

  @override
  Future<Game> update(
    String id, {
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) => _api.update(
    id,
    roundId: roundId,
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    venueId: venueId,
    scheduledAt: scheduledAt,
  );

  @override
  Future<Game> updateStatus(String id, GameStatus status) =>
      _api.updateStatus(id, status);

  @override
  Future<GameBatchResult> createBatch(
    String roundId,
    List<Map<String, dynamic>> items,
  ) => _api.createBatch(roundId, items);
}
