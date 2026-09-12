import 'package:flag_admin_web/domain/enums/competition_team_status.dart';

/// Modelo de Inscrição / Alocação de Time em Competição (ADR-001).
///
/// Uma equipe pertence a um clube/agremiação e pode ser inscrita
/// em competições. O backend retorna apenas o nome do clube (clubName),
/// sem o campo organizationId que causava confusão com o nome da organização.
class CompetitionTeam {
  final String id;
  final String competitionId;
  final String teamId;
  final String teamName;
  final String? teamShortName;
  final String? teamLogoUrl;
  final String? clubId;
  final String? clubName;
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
    this.clubId,
    this.clubName,
    this.status = CompetitionTeamStatus.pending,
    this.groupName,
    this.conferenceName,
    this.divisionName,
    this.seedNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory CompetitionTeam.fromJson(Map<String, dynamic> json) =>
      CompetitionTeam(
        id: json['id'] as String,
        competitionId: json['competitionId'] as String,
        teamId: json['teamId'] as String,
        teamName: (json['teamName'] as String?) ?? 'Sem nome',
        teamShortName: json['teamShortName'] as String?,
        teamLogoUrl: json['teamLogoUrl'] as String?,
        clubId: json['clubId'] as String?,
        clubName: json['clubName'] as String?,
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

  /// Retorna o nome da agremiação/clube mantenedor com fallback amigável.
  String get resolvedInstitutionName {
    if (clubName != null && clubName!.trim().isNotEmpty) {
      return clubName!.trim();
    }
    return 'Não vinculada';
  }

  CompetitionTeam copyWith({
    String? id,
    String? competitionId,
    String? teamId,
    String? teamName,
    String? teamShortName,
    String? teamLogoUrl,
    String? clubId,
    String? clubName,
    CompetitionTeamStatus? status,
    String? groupName,
    String? conferenceName,
    String? divisionName,
    int? seedNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CompetitionTeam(
    id: id ?? this.id,
    competitionId: competitionId ?? this.competitionId,
    teamId: teamId ?? this.teamId,
    teamName: teamName ?? this.teamName,
    teamShortName: teamShortName ?? this.teamShortName,
    teamLogoUrl: teamLogoUrl ?? this.teamLogoUrl,
    clubId: clubId ?? this.clubId,
    clubName: clubName ?? this.clubName,
    status: status ?? this.status,
    groupName: groupName ?? this.groupName,
    conferenceName: conferenceName ?? this.conferenceName,
    divisionName: divisionName ?? this.divisionName,
    seedNumber: seedNumber ?? this.seedNumber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'competitionId': competitionId,
    'teamId': teamId,
    'teamName': teamName,
    'teamShortName': teamShortName,
    'teamLogoUrl': teamLogoUrl,
    if (clubId != null) 'clubId': clubId,
    if (clubName != null) 'clubName': clubName,
    'status': status.toJson(),
    'groupName': groupName,
    'conferenceName': conferenceName,
    'divisionName': divisionName,
    'seedNumber': seedNumber,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
