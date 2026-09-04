import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/game_firestore_service.dart';
import '../domain/entities/game.dart';

/// ViewModel para gerenciar estado dos jogos.
class GameViewModel extends StateNotifier<AsyncValue<List<Game>>> {
  final GameFirestoreService _service;

  GameViewModel(this._service) : super(const AsyncValue.loading()) {
    loadGames();
  }

  /// Carrega todos os jogos.
  Future<void> loadGames() async {
    state = const AsyncValue.loading();
    try {
      final games = await _service.list();
      state = AsyncValue.data(games);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Carrega jogos por competição.
  Future<void> loadGamesByCompetition(String competitionId) async {
    state = const AsyncValue.loading();
    try {
      final games = await _service.listByCompetition(competitionId);
      state = AsyncValue.data(games);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Carrega jogos ativos.
  Future<void> loadActiveGames() async {
    state = const AsyncValue.loading();
    try {
      final games = await _service.listActive();
      state = AsyncValue.data(games);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Cria um novo jogo.
  Future<Game?> createGame({
    required String competitionId,
    required String homeTeamId,
    required String awayTeamId,
    DateTime? scheduledAt,
    String? venueId,
    String? roundId,
  }) async {
    try {
      final game = Game(
        id: '',
        competitionId: competitionId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        scheduledAt: scheduledAt,
        venueId: venueId,
        roundId: roundId,
        status: 'SCHEDULED',
        createdAt: DateTime.now(),
      );
      final created = await _service.create(game);
      await loadGames();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza o placar de um jogo.
  Future<void> updateScore(
    String gameId, {
    required int homeScore,
    required int awayScore,
  }) async {
    try {
      await _service.updateScore(
        gameId,
        homeScore: homeScore,
        awayScore: awayScore,
      );
      await loadGames();
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza o status de um jogo.
  Future<void> updateStatus(String gameId, String status) async {
    try {
      await _service.updateStatus(gameId, status);
      await loadGames();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove um jogo.
  Future<void> deleteGame(String id) async {
    try {
      await _service.delete(id);
      await loadGames();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider para o ViewModel de jogos.
final gameViewModelProvider =
    StateNotifierProvider<GameViewModel, AsyncValue<List<Game>>>(
  (ref) {
    final service = ref.watch(gameFirestoreServiceProvider);
    return GameViewModel(service);
  },
);

/// Provider para stream de jogos ativos.
final activeGamesStreamProvider = StreamProvider<List<Game>>((ref) {
  final service = ref.watch(gameFirestoreServiceProvider);
  return service.streamActive();
});
