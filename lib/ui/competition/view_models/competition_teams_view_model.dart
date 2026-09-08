import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/competition_team_repository.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/models/competition_team.dart';
import 'package:flag_admin_web/src/domain/enums/competition_team_status.dart';

/// ViewModel para Gerenciamento e Homologação de Equipes em Competições.
class CompetitionTeamsViewModel extends ChangeNotifier {
  final CompetitionTeamRepository _repository;
  final String competitionId;
  final Competition? competition;

  CompetitionTeamsViewModel({
    required CompetitionTeamRepository repository,
    required this.competitionId,
    this.competition,
  }) : _repository = repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _actionInProgressTeamId;
  String? get actionInProgressTeamId => _actionInProgressTeamId;

  List<CompetitionTeam> _teams = [];
  List<CompetitionTeam> get teams => _teams;

  List<Map<String, dynamic>> _platformTeams = [];
  List<Map<String, dynamic>> get platformTeams => _platformTeams;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  CompetitionTeamStatus? _statusFilter;
  CompetitionTeamStatus? get statusFilter => _statusFilter;

  String? _groupFilter;
  String? get groupFilter => _groupFilter;

  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getTeamsByCompetition(competitionId, forceRefresh: forceRefresh),
        _repository.listAllPlatformTeams(),
      ]);
      _teams = results[0] as List<CompetitionTeam>;
      _platformTeams = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      _errorMessage = 'Erro ao carregar equipes da competição: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setStatusFilter(CompetitionTeamStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setGroupFilter(String? group) {
    _groupFilter = group;
    notifyListeners();
  }

  List<CompetitionTeam> get filteredTeams {
    return _teams.where((team) {
      if (_statusFilter != null && team.status != _statusFilter) {
        return false;
      }
      if (_groupFilter != null && _groupFilter!.isNotEmpty) {
        final currentGroup = team.groupName ?? team.conferenceName ?? '';
        if (currentGroup != _groupFilter) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final name = team.teamName.toLowerCase();
        final org = (team.organizationName ?? '').toLowerCase();
        final group = (team.groupName ?? '').toLowerCase();
        final conf = (team.conferenceName ?? '').toLowerCase();
        return name.contains(_searchQuery) ||
            org.contains(_searchQuery) ||
            group.contains(_searchQuery) ||
            conf.contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get availableTeamsToEnroll {
    final enrolledTeamIds = _teams.map((t) => t.teamId).toSet();
    return _platformTeams
        .where((pt) => !enrolledTeamIds.contains(pt['id']))
        .toList();
  }

  Future<bool> enrollTeam({
    required String teamId,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.enrollTeam(
        competitionId: competitionId,
        teamId: teamId,
        status: CompetitionTeamStatus.pending,
        groupName: groupName,
        conferenceName: conferenceName,
        divisionName: divisionName,
        seedNumber: seedNumber,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao inscrever time: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAllocation({
    required String teamId,
    CompetitionTeamStatus? status,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
  }) async {
    _actionInProgressTeamId = teamId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateAllocation(
        competitionId: competitionId,
        teamId: teamId,
        status: status,
        groupName: groupName,
        conferenceName: conferenceName,
        divisionName: divisionName,
        seedNumber: seedNumber,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar alocação: $e';
      return false;
    } finally {
      _actionInProgressTeamId = null;
      notifyListeners();
    }
  }

  Future<bool> approveTeam(String teamId) async {
    _actionInProgressTeamId = teamId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.approveTeam(
        competitionId: competitionId,
        teamId: teamId,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao homologar equipe: $e';
      return false;
    } finally {
      _actionInProgressTeamId = null;
      notifyListeners();
    }
  }

  Future<bool> rejectTeam(String teamId) async {
    _actionInProgressTeamId = teamId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.rejectTeam(
        competitionId: competitionId,
        teamId: teamId,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao rejeitar equipe: $e';
      return false;
    } finally {
      _actionInProgressTeamId = null;
      notifyListeners();
    }
  }

  Future<bool> removeTeam(String teamId) async {
    _actionInProgressTeamId = teamId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.removeFromCompetition(
        competitionId: competitionId,
        teamId: teamId,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao desinscrever equipe: $e';
      return false;
    } finally {
      _actionInProgressTeamId = null;
      notifyListeners();
    }
  }
}
