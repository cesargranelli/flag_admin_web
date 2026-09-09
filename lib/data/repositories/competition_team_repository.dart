import 'package:flag_admin_web/data/services/competition_team_service.dart';
import 'package:flag_admin_web/domain/models/competition_team.dart';
import 'package:flag_admin_web/src/domain/enums/competition_team_status.dart';

/// Repositório de Inscrições de Equipes (ADR-001 - Cache TTL 30s).
class CompetitionTeamRepository {
  final CompetitionTeamService _service;

  CompetitionTeamRepository({required CompetitionTeamService service})
      : _service = service;

  final Map<String, List<CompetitionTeam>> _cacheByComp = {};
  final Map<String, DateTime> _lastFetchByComp = {};
  static const Duration _cacheTtl = Duration(seconds: 30);

  Future<List<CompetitionTeam>> getTeamsByCompetition(
    String competitionId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cacheByComp[competitionId];
    final lastFetch = _lastFetchByComp[competitionId];
    final isCacheValid = cached != null &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < _cacheTtl;

    if (!forceRefresh && isCacheValid) {
      return cached;
    }

    final data = await _service.listByCompetition(competitionId);
    _cacheByComp[competitionId] = List<CompetitionTeam>.unmodifiable(data);
    _lastFetchByComp[competitionId] = DateTime.now();
    return _cacheByComp[competitionId]!;
  }

  Future<CompetitionTeam> enrollTeam({
    required String competitionId,
    required String teamId,
    CompetitionTeamStatus status = CompetitionTeamStatus.pending,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
  }) async {
    final enrolled = await _service.enrollTeam(
      competitionId: competitionId,
      teamId: teamId,
      status: status,
      groupName: groupName,
      conferenceName: conferenceName,
      divisionName: divisionName,
      seedNumber: seedNumber,
    );
    clearCache(competitionId);
    return enrolled;
  }

  Future<CompetitionTeam> updateAllocation({
    required String competitionId,
    required String teamId,
    CompetitionTeamStatus? status,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
  }) async {
    final updated = await _service.updateAllocation(
      competitionId: competitionId,
      teamId: teamId,
      status: status,
      groupName: groupName,
      conferenceName: conferenceName,
      divisionName: divisionName,
      seedNumber: seedNumber,
    );
    clearCache(competitionId);
    return updated;
  }

  Future<CompetitionTeam> approveTeam({
    required String competitionId,
    required String teamId,
  }) async {
    final approved = await _service.approveTeam(
      competitionId: competitionId,
      teamId: teamId,
    );
    clearCache(competitionId);
    return approved;
  }

  Future<CompetitionTeam> rejectTeam({
    required String competitionId,
    required String teamId,
  }) async {
    final rejected = await _service.rejectTeam(
      competitionId: competitionId,
      teamId: teamId,
    );
    clearCache(competitionId);
    return rejected;
  }

  Future<void> removeFromCompetition({
    required String competitionId,
    required String teamId,
  }) async {
    await _service.removeFromCompetition(
      competitionId: competitionId,
      teamId: teamId,
    );
    clearCache(competitionId);
  }

  Future<List<CompetitionTeam>> getCompetitionsByTeam(String teamId) =>
      _service.listByTeam(teamId);

  Future<List<Map<String, dynamic>>> listAllPlatformTeams() =>
      _service.listAllPlatformTeams();

  void clearCache(String? competitionId) {
    if (competitionId != null) {
      _cacheByComp.remove(competitionId);
      _lastFetchByComp.remove(competitionId);
    } else {
      _cacheByComp.clear();
      _lastFetchByComp.clear();
    }
  }
}
