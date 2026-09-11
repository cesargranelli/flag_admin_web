import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/competition_repository.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/enums/competition_status.dart';
import 'package:flag_admin_web/domain/enums/modality.dart';

/// ViewModel para a listagem e gestão de Competições (ADR-001 / MVVM).
class CompetitionListViewModel extends ChangeNotifier {
  final CompetitionRepository _repository;

  CompetitionListViewModel({required CompetitionRepository repository})
    : _repository = repository;

  List<Competition> _competitions = const [];
  List<Competition> get competitions => _competitions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _seasonFilter;
  String? get seasonFilter => _seasonFilter;

  CompetitionStatus? _statusFilter;
  CompetitionStatus? get statusFilter => _statusFilter;

  Modality? _modalityFilter;
  Modality? get modalityFilter => _modalityFilter;

  bool _showDisabled = false;
  bool get showDisabled => _showDisabled;

  String? _actionInProgressId;
  String? get actionInProgressId => _actionInProgressId;

  /// Retorna as competições filtradas por busca, temporada, status e modalidade.
  List<Competition> get filteredCompetitions {
    return _competitions
        .where((comp) {
          if (!_showDisabled && comp.status == CompetitionStatus.disabled) {
            return false;
          }
          if (_seasonFilter != null && _seasonFilter!.isNotEmpty) {
            if (comp.season != _seasonFilter) return false;
          }
          if (_statusFilter != null && comp.status != _statusFilter) {
            return false;
          }
          if (_modalityFilter != null && comp.modality != _modalityFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            final nameMatch = comp.name.toLowerCase().contains(query);
            final orgMatch =
                comp.organizationName?.toLowerCase().contains(query) ?? false;
            if (!nameMatch && !orgMatch) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  /// Lista de temporadas únicas disponíveis para filtro.
  List<String> get availableSeasons {
    final seasons = _competitions
        .map((c) => c.season)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    seasons.sort((a, b) => b.compareTo(a));
    return seasons;
  }

  /// Carrega as competições com suporte a Stale-While-Revalidate.
  Future<void> load({bool forceRefresh = false, bool silent = false}) async {
    if (_competitions.isEmpty && !silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final items = await _repository.getCompetitions(
        includeDisabled: _showDisabled,
        forceRefresh: forceRefresh,
      );
      _competitions = items;
      _errorMessage = null;
    } catch (e) {
      if (_competitions.isEmpty) {
        _errorMessage = 'Não foi possível carregar as competições.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSeasonFilter(String? season) {
    _seasonFilter = season;
    notifyListeners();
  }

  void setStatusFilter(CompetitionStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setModalityFilter(Modality? modality) {
    _modalityFilter = modality;
    notifyListeners();
  }

  void toggleShowDisabled() {
    _showDisabled = !_showDisabled;
    load(forceRefresh: true);
  }

  Future<bool> deactivate(Competition competition) async {
    _actionInProgressId = competition.id;
    notifyListeners();
    try {
      await _repository.deactivateCompetition(competition.id);
      await load(forceRefresh: true, silent: true);
      return true;
    } catch (e) {
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }

  Future<bool> reactivate(Competition competition) async {
    _actionInProgressId = competition.id;
    notifyListeners();
    try {
      await _repository.reactivateCompetition(competition.id);
      await load(forceRefresh: true, silent: true);
      return true;
    } catch (e) {
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }
}
