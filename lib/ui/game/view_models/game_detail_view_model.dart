import 'package:flag_admin_web/data/repositories/game_repository.dart';
import 'package:flag_admin_web/domain/enums/game_status.dart';
import 'package:flag_admin_web/domain/models/game.dart';
import 'package:flutter/foundation.dart';

/// ViewModel para o detalhe de um Jogo (ADR-011 / MVVM).
class GameDetailViewModel extends ChangeNotifier {
  final GameRepository _repository;

  GameDetailViewModel({required GameRepository repository})
    : _repository = repository;

  Game? _game;

  Game? get game => _game;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Carrega o jogo por ID.
  Future<void> load(String gameId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final games = await _repository.getGamesByCompetition(
        _game?.competitionId ?? '',
        forceRefresh: true,
      );
      _game = games.firstWhere(
        (g) => g.id == gameId,
        orElse: () => throw Exception('Jogo não encontrado'),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Não foi possível carregar o jogo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Define o jogo diretamente (quando navegado via extra).
  void setGame(Game game) {
    _game = game;
    notifyListeners();
  }

  /// Atualiza o status do jogo.
  Future<bool> updateStatus(GameStatus status) async {
    final game = _game;
    if (game == null || game.competitionId == null) return false;

    try {
      _game = await _repository.updateStatus(
        game.id,
        competitionId: game.competitionId!,
        status: status,
      );
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
