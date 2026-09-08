import 'package:flag_admin_web/data/services/competition_team_service.dart';
import 'package:flag_admin_web/domain/models/competition_team.dart';
import 'package:flag_admin_web/src/api/api_client.dart';
import 'package:flag_admin_web/src/domain/enums/competition_team_status.dart';

/// Implementação REST de CompetitionTeamService.
class ApiCompetitionTeamService implements CompetitionTeamService {
  final ApiClient _client;

  ApiCompetitionTeamService(this._client);

  @override
  Future<List<CompetitionTeam>> listByCompetition(String competitionId) =>
      _client.getList(
        '/api/v1/competitions/$competitionId/teams',
        CompetitionTeam.fromJson,
      );

  @override
  Future<CompetitionTeam> enrollTeam({
    required String competitionId,
    required String teamId,
    CompetitionTeamStatus status = CompetitionTeamStatus.pending,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
  }) =>
      _client.post(
        '/api/v1/competitions/$competitionId/teams/$teamId',
        {
          'status': status.toJson(),
          if (groupName != null && groupName.isNotEmpty) 'groupName': groupName,
          if (conferenceName != null && conferenceName.isNotEmpty)
            'conferenceName': conferenceName,
          if (divisionName != null && divisionName.isNotEmpty)
            'divisionName': divisionName,
          'seedNumber': ?seedNumber,
        },
        CompetitionTeam.fromJson,
      );

  @override
  Future<CompetitionTeam> updateAllocation({
    required String competitionId,
    required String teamId,
    CompetitionTeamStatus? status,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
  }) =>
      _client.put(
        '/api/v1/competitions/$competitionId/teams/$teamId',
        {
          if (status != null) 'status': status.toJson(),
          'groupName': groupName,
          'conferenceName': conferenceName,
          'divisionName': divisionName,
          'seedNumber': seedNumber,
        },
        CompetitionTeam.fromJson,
      );

  @override
  Future<CompetitionTeam> approveTeam({
    required String competitionId,
    required String teamId,
  }) =>
      _client.post(
        '/api/v1/competitions/$competitionId/teams/$teamId/approve',
        {},
        CompetitionTeam.fromJson,
      );

  @override
  Future<CompetitionTeam> rejectTeam({
    required String competitionId,
    required String teamId,
  }) =>
      _client.post(
        '/api/v1/competitions/$competitionId/teams/$teamId/reject',
        {},
        CompetitionTeam.fromJson,
      );

  @override
  Future<void> removeFromCompetition({
    required String competitionId,
    required String teamId,
  }) =>
      _client.delete('/api/v1/competitions/$competitionId/teams/$teamId');

  @override
  Future<List<Map<String, dynamic>>> listAllPlatformTeams() => _client.getList(
        '/api/v1/teams',
        (json) => Map<String, dynamic>.from(json),
      );
}
