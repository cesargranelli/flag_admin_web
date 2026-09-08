import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/competition_repository.dart';
import 'package:flag_admin_web/domain/models/competition.dart';

/// ViewModel da tela de Detalhes de Competição (ADR-001 / MVVM 1:1).
class CompetitionDetailViewModel extends ChangeNotifier {
  final CompetitionRepository _repository;
  final String competitionId;

  Competition? _competition;
  Competition? get competition => _competition;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CompetitionDetailViewModel({
    required CompetitionRepository repository,
    required this.competitionId,
    Competition? initialCompetition,
  })  : _repository = repository,
        _competition = initialCompetition;

  /// Carrega os dados da competição por ID a partir do repositório.
  Future<void> load({bool forceRefresh = false}) async {
    if (_competition != null && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _competition = await _repository.getCompetition(
        competitionId,
        forceRefresh: forceRefresh,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
