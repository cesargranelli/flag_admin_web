/// Time de um clube/universidade.
///
/// Representa a entidade esportiva dentro de uma organização.
/// Um clube pode ter N times. O time é inscrito em competições
/// via [CompetitionTeam].
///
/// Shape de `/api/v1/organizations/{orgId}/teams` e
/// `/api/v1/teams/{id}`.
class Team {
  final String id;

  /// Organização (clube/universidade) dona do time — obrigatória.
  final String organizationId;
  final String name;
  final String? shortName;
  final String? sportName;
  final String? logoUrl;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Team({
    required this.id,
    required this.organizationId,
    required this.name,
    this.shortName,
    this.sportName,
    this.logoUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        organizationId: json['organizationId'] as String,
        name: json['name'] as String,
        shortName: json['shortName'] as String?,
        sportName: json['sportName'] as String?,
        logoUrl: json['logoUrl'] as String?,
        status: json['status'] as String?,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/organizations/{orgId}/teams`).
  ///
  /// `organizationId` é obrigatório no backend.
  Map<String, dynamic> toJson() => {
        'organizationId': organizationId,
        'name': name,
        if (shortName != null) 'shortName': shortName,
        if (sportName != null) 'sportName': sportName,
        if (logoUrl != null) 'logoUrl': logoUrl,
      };
}
