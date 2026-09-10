import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/game_repository.dart';
import 'package:flag_admin_web/domain/models/game.dart';

/// ViewModel para a listagem de Jogos por rodada (ADR-011 / MVVM).
class GameListViewModel extends ChangeNotifier {
  final GameRepository _repository;

  GameListViewModel({required GameRepository repository})
      : _repository = repository;

  List<Game> _games = const [];
  List<Game> get games => _games;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRevalidating = false;
  bool get isRevalidating => _isRevalidating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedCompetitionId;
  String? get selectedCompetitionId => _selectedCompetitionId;

  String? _selectedRoundId;
  String? get selectedRoundId => _selectedRoundId;

  /// Retorna os jogos filtrados por busca.
  List<Game> get filteredGames {
    if (_searchQuery.isEmpty) return _games;
    final query = _searchQuery.toLowerCase().trim();
    return _games
        .where((g) =>
            (g.homeTeamName ?? '').toLowerCase().contains(query) ||
            (g.awayTeamName ?? '').toLowerCase().contains(query))
        .toList(growable: false);
  }

  /// Carrega os jogos de uma competição (Stale-While-Revalidate).
  Future<void> load({
    String? competitionId,
    String? roundId,
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (competitionId != null) _selectedCompetitionId = competitionId;
    if (roundId != null) _selectedRoundId = roundId;

    if (_games.isEmpty && !silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isRevalidating = true;
      notifyListeners();
    }

    try {
      final compId = _selectedCompetitionId;
      if (compId == null) {
        _games = const [];
      } else {
        final data = await _repository.getGamesByCompetition(
          compId,
          forceRefresh: forceRefresh,
        );
        _games = List<Game>.unmodifiable(data);
      }
      _errorMessage = null;
    } catch (e) {
      if (_games.isEmpty) {
        _errorMessage = 'Não foi possível carregar os jogos.';
      }
    } finally {
      _isLoading = false;
      _isRevalidating = false;
      notifyListeners();
    }
  }

  /// Filtra jogos por rodada (client-side).
  List<Game> getGamesByRound(String roundId) {
    return _games.where((g) => g.roundId == roundId).toList(growable: false);
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void setSelectedCompetition(String? competitionId) {
    if (_selectedCompetitionId != competitionId) {
      _selectedCompetitionId = competitionId;
      _selectedRoundId = null;
      _games = const [];
      notifyListeners();
      load(forceRefresh: true);
    }
  }

  void setSelectedRound(String? roundId) {
    if (_selectedRoundId != roundId) {
      _selectedRoundId = roundId;
      notifyListeners();
    }
  }
}
