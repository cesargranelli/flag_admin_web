import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/game_repository.dart';
import 'package:flag_admin_web/domain/models/game.dart';

/// ViewModel para a edição de um Jogo existente (ADR-011 / MVVM).
class GameEditViewModel extends ChangeNotifier {
  final GameRepository _repository;

  GameEditViewModel({required GameRepository repository})
      : _repository = repository;

  // Form state
  String? _roundId;
  String? _homeTeamId;
  String? _awayTeamId;
  String? _venueId;
  DateTime? _scheduledAt;
  String? _competitionId;
  String? _gameId;

  // Getters
  String? get roundId => _roundId;
  String? get homeTeamId => _homeTeamId;
  String? get awayTeamId => _awayTeamId;
  String? get venueId => _venueId;
  DateTime? get scheduledAt => _scheduledAt;
  String? get competitionId => _competitionId;
  String? get gameId => _gameId;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Inicializa o formulário com dados de um jogo existente.
  void init(Game game) {
    _gameId = game.id;
    _roundId = game.roundId;
    _homeTeamId = game.homeTeamId;
    _awayTeamId = game.awayTeamId;
    _venueId = game.venueId;
    _scheduledAt = game.scheduledAt;
    _competitionId = game.competitionId;
    notifyListeners();
  }

  // Setters
  void setRoundId(String? value) {
    _roundId = value;
    notifyListeners();
  }

  void setHomeTeamId(String? value) {
    _homeTeamId = value;
    notifyListeners();
  }

  void setAwayTeamId(String? value) {
    _awayTeamId = value;
    notifyListeners();
  }

  void setVenueId(String? value) {
    _venueId = value;
    notifyListeners();
  }

  void setScheduledAt(DateTime? value) {
    _scheduledAt = value;
    notifyListeners();
  }

  /// Salva as alterações do jogo.
  Future<bool> save() async {
    final competitionId = _competitionId;
    final gameId = _gameId;
    final roundId = _roundId;
    final homeTeamId = _homeTeamId;
    final awayTeamId = _awayTeamId;
    final scheduledAt = _scheduledAt;

    if (competitionId == null ||
        gameId == null ||
        roundId == null ||
        homeTeamId == null ||
        awayTeamId == null ||
        scheduledAt == null) {
      _errorMessage = 'Preencha todos os campos obrigatórios.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateGame(
        gameId,
        competitionId: competitionId,
        roundId: roundId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        venueId: _venueId,
        scheduledAt: scheduledAt,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Não foi possível salvar o jogo.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
