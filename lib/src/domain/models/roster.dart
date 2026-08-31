/// Elenco de um [Team] para uma [Competition] específica.
///
/// Um time pode ter elencos diferentes por competição.
/// Cada elenco contém as [RosterEntry]s (atletas vinculados).
///
/// Shape de `/api/v1/teams/{teamId}/roster` (quando filtrado por competição).
class Roster {
  final String id;
  final String teamId;
  final String competitionId;
  final String? name;
  final String? season;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Roster({
    required this.id,
    required this.teamId,
    required this.competitionId,
    this.name,
    this.season,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Roster.fromJson(Map<String, dynamic> json) => Roster(
        id: json['id'] as String,
        teamId: json['teamId'] as String,
        competitionId: json['competitionId'] as String,
        name: json['name'] as String?,
        season: json['season'] as String?,
        status: json['status'] as String?,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'competitionId': competitionId,
        if (name != null) 'name': name,
        if (season != null) 'season': season,
      };
}
