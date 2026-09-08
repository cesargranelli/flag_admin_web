import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import 'package:flag_admin_web/domain/models/team.dart';

/// ViewModel da tela de Detalhes de Agremiação (ADR-001 / MVVM).
class InstitutionDetailViewModel extends ChangeNotifier {
  final InstitutionRepository _repository;
  final String institutionId;

  Institution? _institution;
  Institution? get institution => _institution;

  List<Team> _teams = [];
  List<Team> get teams => _teams;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingTeams = false;
  bool get isLoadingTeams => _isLoadingTeams;

  bool _isSavingTeam = false;
  bool get isSavingTeam => _isSavingTeam;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _teamsErrorMessage;
  String? get teamsErrorMessage => _teamsErrorMessage;

  InstitutionDetailViewModel({
    required InstitutionRepository repository,
    required this.institutionId,
    Institution? initialInstitution,
  })  : _repository = repository,
        _institution = initialInstitution;

  /// Carrega os dados da agremiação e suas equipes a partir do repositório.
  Future<void> load({bool forceRefresh = false}) async {
    final shouldLoadInst = _institution == null || forceRefresh;

    if (shouldLoadInst) {
      _isLoading = true;
      _errorMessage = null;
    }
    _isLoadingTeams = true;
    _teamsErrorMessage = null;
    notifyListeners();

    try {
      if (shouldLoadInst) {
        _institution = await _repository.getInstitution(
          institutionId,
          forceRefresh: forceRefresh,
        );
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    try {
      _teams = await _repository.getTeams(
        institutionId,
        forceRefresh: forceRefresh,
      );
      _teamsErrorMessage = null;
    } catch (e) {
      _teamsErrorMessage = e.toString();
    } finally {
      _isLoadingTeams = false;
      notifyListeners();
    }
  }

  /// Recarrega apenas a lista de equipes esportivas.
  Future<void> loadTeams({bool forceRefresh = true}) async {
    _isLoadingTeams = true;
    _teamsErrorMessage = null;
    notifyListeners();

    try {
      _teams = await _repository.getTeams(
        institutionId,
        forceRefresh: forceRefresh,
      );
      _teamsErrorMessage = null;
    } catch (e) {
      _teamsErrorMessage = e.toString();
    } finally {
      _isLoadingTeams = false;
      notifyListeners();
    }
  }

  /// Cria uma nova equipe esportiva vinculada a esta agremiação.
  Future<bool> createTeam({
    required String name,
    String? shortName,
    String? sportName,
    String? logoUrl,
  }) async {
    _isSavingTeam = true;
    notifyListeners();

    try {
      await _repository.createTeam(
        institutionId: institutionId,
        name: name,
        shortName: shortName,
        sportName: sportName,
        logoUrl: logoUrl,
      );
      await loadTeams(forceRefresh: true);
      return true;
    } catch (e) {
      _teamsErrorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSavingTeam = false;
      notifyListeners();
    }
  }

  /// Exclui uma equipe esportiva.
  Future<bool> deleteTeam(String teamId) async {
    try {
      await _repository.deleteTeam(institutionId, teamId);
      await loadTeams(forceRefresh: true);
      return true;
    } catch (e) {
      _teamsErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Desativa logicamente uma equipe esportiva.
  Future<bool> deactivateTeam(String teamId) async {
    try {
      await _repository.deactivateTeam(institutionId, teamId);
      await loadTeams(forceRefresh: true);
      return true;
    } catch (e) {
      _teamsErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reativa uma equipe esportiva.
  Future<bool> reactivateTeam(String teamId) async {
    try {
      await _repository.reactivateTeam(institutionId, teamId);
      await loadTeams(forceRefresh: true);
      return true;
    } catch (e) {
      _teamsErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

