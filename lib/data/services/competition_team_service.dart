import 'package:flag_admin_web/domain/models/competition_team.dart';
import 'package:flag_admin_web/src/domain/enums/competition_team_status.dart';

/// Contrato do serviço de Inscrições e Alocações de Times em Competições.
abstract class CompetitionTeamService {
  Future<List<CompetitionTeam>> listByCompetition(String competitionId);

  Future<CompetitionTeam> enrollTeam({
    required String competitionId,
    required String teamId,
    CompetitionTeamStatus status = CompetitionTeamStatus.pending,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
  });

  Future<CompetitionTeam> updateAllocation({
    required String competitionId,
    required String teamId,
    CompetitionTeamStatus? status,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
  });

  Future<CompetitionTeam> approveTeam({
    required String competitionId,
    required String teamId,
  });

  Future<CompetitionTeam> rejectTeam({
    required String competitionId,
    required String teamId,
  });

  Future<void> removeFromCompetition({
    required String competitionId,
    required String teamId,
  });

  /// Lista todos os times cadastrados no sistema (para seleção na inscrição)
  Future<List<Map<String, dynamic>>> listAllPlatformTeams();
}
