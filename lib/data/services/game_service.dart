import 'package:flag_admin_web/domain/models/game.dart';

abstract class GameService {
  Future<List<Game>> listByCompetition(String competitionId);
  Future<List<Game>> listByRound(String roundId);
  Future<Game> getById(String id);
  Future<Game> create({
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  });
  Future<Game> update(
    String id, {
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  });
  Future<Game> updateStatus(String id, GameStatus status);
}
