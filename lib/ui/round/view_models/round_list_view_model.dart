import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/round_repository.dart';
import 'package:flag_admin_web/domain/models/round.dart';

/// ViewModel para a listagem de Rodadas por competição (ADR-011 / MVVM).
class RoundListViewModel extends ChangeNotifier {
  final RoundRepository _repository;

  RoundListViewModel({required RoundRepository repository})
      : _repository = repository;

  List<Round> _rounds = const [];
  List<Round> get rounds => _rounds;

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

  /// Retorna as rodadas filtradas por busca.
  List<Round> get filteredRounds {
    if (_searchQuery.isEmpty) return _rounds;
    final query = _searchQuery.toLowerCase().trim();
    return _rounds
        .where((r) =>
            r.name.toLowerCase().contains(query) ||
            r.number.toString().contains(query))
        .toList(growable: false);
  }

  /// Carrega as rodadas de uma competição (Stale-While-Revalidate).
  Future<void> load({
    String? competitionId,
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (competitionId != null) _selectedCompetitionId = competitionId;

    if (_rounds.isEmpty && !silent) {
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
        _rounds = const [];
      } else {
        final data = await _repository.getRoundsByCompetition(
          compId,
          forceRefresh: forceRefresh,
        );
        _rounds = List<Round>.unmodifiable(data);
      }
      _errorMessage = null;
    } catch (e) {
      if (_rounds.isEmpty) {
        _errorMessage = 'Não foi possível carregar as rodadas.';
      }
    } finally {
      _isLoading = false;
      _isRevalidating = false;
      notifyListeners();
    }
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
      _rounds = const [];
      notifyListeners();
      load(forceRefresh: true);
    }
  }
}