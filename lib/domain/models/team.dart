import 'package:flag_admin_web/src/domain/enums/document_type.dart';

/// Equipe Esportiva do Flag Platform (Domain Model - ADR-001).
///
/// Uma equipe pertence a uma organização (clube/universidade) e pode ser inscrita
/// em competições através do modelo de inscrição `CompetitionTeam`.
class Team {
  final String id;

  /// Id da agremiação/clube a qual a equipe pertence.
  final String? organizationId;

  /// Id opcional da competição (para compatibilidade com endpoints legados).
  final String? competitionId;
  final String? divisionId;

  /// Nome da equipe esportiva (ex: "Spartans Black", "Spartans Feminino").
  final String name;
  final String? shortName;

  /// Modalidade / Esporte (ex: "Flag Football 5x5 Masculino", "Tackle Full Pads").
  final String? sportName;
  final int? athleteCount;
  final String? document;
  final DocumentType? documentType;
  final String? logoUrl;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Team({
    required this.id,
    this.organizationId,
    this.competitionId,
    this.divisionId,
    required this.name,
    this.shortName,
    this.sportName,
    this.athleteCount,
    this.document,
    this.documentType,
    this.logoUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        organizationId: json['organizationId'] as String?,
        competitionId: json['competitionId'] as String?,
        divisionId: json['divisionId'] as String?,
        name: (json['name'] as String?) ?? '',
        shortName: json['shortName'] as String?,
        sportName: json['sportName'] as String?,
        athleteCount: json['athleteCount'] as int?,
        document: json['document'] as String?,
        documentType: json['documentType'] is String
            ? DocumentType.fromJson(json['documentType'] as String)
            : null,
        logoUrl: json['logoUrl'] as String?,
        status: json['status'] as String?,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (organizationId != null) 'organizationId': organizationId,
        if (competitionId != null) 'competitionId': competitionId,
        if (divisionId != null) 'divisionId': divisionId,
        'name': name,
        if (shortName != null) 'shortName': shortName,
        if (sportName != null) 'sportName': sportName,
        if (athleteCount != null) 'athleteCount': athleteCount,
        if (document != null) 'document': document,
        if (documentType != null) 'documentType': documentType!.toJson(),
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (status != null) 'status': status,
      };
}
