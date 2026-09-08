import 'package:flag_admin_web/src/domain/enums/competition_team_status.dart';

/// Modelo de Inscrição / Alocação de Time em Competição (ADR-001).
class CompetitionTeam {
  final String id;
  final String competitionId;
  final String teamId;
  final String teamName;
  final String? teamShortName;
  final String? teamLogoUrl;
  final String? organizationId;
  final String? organizationName;
  final CompetitionTeamStatus status;
  final String? groupName;
  final String? conferenceName;
  final String? divisionName;
  final int? seedNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompetitionTeam({
    required this.id,
    required this.competitionId,
    required this.teamId,
    required this.teamName,
    this.teamShortName,
    this.teamLogoUrl,
    this.organizationId,
    this.organizationName,
    this.status = CompetitionTeamStatus.pending,
    this.groupName,
    this.conferenceName,
    this.divisionName,
    this.seedNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory CompetitionTeam.fromJson(Map<String, dynamic> json) => CompetitionTeam(
        id: json['id'] as String,
        competitionId: json['competitionId'] as String,
        teamId: json['teamId'] as String,
        teamName: (json['teamName'] as String?) ?? 'Sem nome',
        teamShortName: json['teamShortName'] as String?,
        teamLogoUrl: json['teamLogoUrl'] as String?,
        organizationId: json['organizationId'] as String?,
        organizationName: json['organizationName'] as String?,
        status: json['status'] != null
            ? CompetitionTeamStatus.fromJson(json['status'] as String)
            : CompetitionTeamStatus.pending,
        groupName: json['groupName'] as String?,
        conferenceName: json['conferenceName'] as String?,
        divisionName: json['divisionName'] as String?,
        seedNumber: json['seedNumber'] as int?,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'competitionId': competitionId,
        'teamId': teamId,
        'teamName': teamName,
        'teamShortName': teamShortName,
        'teamLogoUrl': teamLogoUrl,
        'organizationId': organizationId,
        'organizationName': organizationName,
        'status': status.toJson(),
        'groupName': groupName,
        'conferenceName': conferenceName,
        'divisionName': divisionName,
        'seedNumber': seedNumber,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
