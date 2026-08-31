/// Inscrição de um [Team] em uma [Competition].
///
/// Tabela pivô que substitui o antigo campo `competitionId` no `Team`.
/// Um time pode ser inscrito em N competições; uma competição tem N times.
///
/// Shape de `/api/v1/competitions/{competitionId}/teams`.
class CompetitionTeam {
  final String id;
  final String competitionId;
  final String teamId;
  final String? divisionId;

  /// Dados derivados do time (para exibição na listagem da competição).
  final String? teamName;
  final String? teamLogoUrl;
  final String? organizationId;
  final String? organizationName;

  /// Contagem de atletas no elenco deste time nesta competição.
  final int? athleteCount;

  final DateTime? createdAt;

  const CompetitionTeam({
    required this.id,
    required this.competitionId,
    required this.teamId,
    this.divisionId,
    this.teamName,
    this.teamLogoUrl,
    this.organizationId,
    this.organizationName,
    this.athleteCount,
    this.createdAt,
  });

  factory CompetitionTeam.fromJson(Map<String, dynamic> json) =>
      CompetitionTeam(
        id: json['id'] as String,
        competitionId: json['competitionId'] as String,
        teamId: json['teamId'] as String,
        divisionId: json['divisionId'] as String?,
        teamName: json['teamName'] as String?,
        teamLogoUrl: json['teamLogoUrl'] as String?,
        organizationId: json['organizationId'] as String?,
        organizationName: json['organizationName'] as String?,
        athleteCount: json['athleteCount'] as int?,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        if (divisionId != null) 'divisionId': divisionId,
      };
}
