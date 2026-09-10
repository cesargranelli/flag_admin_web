import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/competition_repository.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/models/enrollment_window.dart';

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

  // --- Janela de Inscrição ---
  EnrollmentWindow? _enrollmentWindow;
  EnrollmentWindow? get enrollmentWindow => _enrollmentWindow;

  bool _isLoadingWindow = false;
  bool get isLoadingWindow => _isLoadingWindow;

  bool _isSavingWindow = false;
  bool get isSavingWindow => _isSavingWindow;

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

  /// Carrega a janela de inscrição da competição.
  Future<void> loadEnrollmentWindow() async {
    _isLoadingWindow = true;
    notifyListeners();

    try {
      _enrollmentWindow = await _repository.getEnrollmentWindow(competitionId);
    } catch (_) {
      _enrollmentWindow = null;
    } finally {
      _isLoadingWindow = false;
      notifyListeners();
    }
  }

  /// Abre ou atualiza a janela de inscrição.
  Future<bool> openEnrollmentWindow({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? instructions,
  }) async {
    _isSavingWindow = true;
    notifyListeners();

    try {
      _enrollmentWindow = await _repository.openEnrollmentWindow(
        competitionId,
        {
          'title': title,
          'startDate': startDate.toIso8601String().substring(0, 10),
          'endDate': endDate.toIso8601String().substring(0, 10),
          if (instructions != null && instructions.isNotEmpty)
            'instructions': instructions,
        },
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSavingWindow = false;
      notifyListeners();
    }
  }

  /// Encerra a janela de inscrição.
  Future<bool> closeEnrollmentWindow() async {
    _isSavingWindow = true;
    notifyListeners();

    try {
      _enrollmentWindow = await _repository.closeEnrollmentWindow(competitionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSavingWindow = false;
      notifyListeners();
    }
  }
}
