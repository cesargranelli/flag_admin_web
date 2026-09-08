import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';
import 'package:flag_admin_web/src/domain/enums/modality.dart';
import 'package:flag_admin_web/src/domain/enums/tournament_format.dart';

/// Competição / Torneio esportivo (Domain Model - ADR-001).
class Competition {
  final String id;
  final String name;
  final CompetitionStatus status;
  final String? organizationId;
  final String? organizationName;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String season;
  final TournamentFormat tournamentFormat;
  final Modality? modality;
  final String? gender;
  final String? ageGroup;
  final GroupingType? groupingType;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Competition({
    required this.id,
    required this.name,
    required this.status,
    this.season = '2026',
    this.tournamentFormat = TournamentFormat.roundRobin,
    this.organizationId,
    this.organizationName,
    this.description,
    this.startDate,
    this.endDate,
    this.modality,
    this.gender,
    this.ageGroup,
    this.groupingType,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Competition.fromJson(Map<String, dynamic> json) => Competition(
        id: json['id'] as String,
        name: json['name'] as String,
        status: CompetitionStatus.fromJson(json['status'] as String),
        season: (json['season'] as String?) ?? '2026',
        tournamentFormat: TournamentFormat.tryFromJson(
                json['tournamentFormat'] as String? ??
                    json['format'] as String?) ??
            TournamentFormat.roundRobin,
        organizationId: json['organizationId'] as String?,
        organizationName: json['organizationName'] as String?,
        description: json['description'] as String?,
        startDate: _tryParseDate(json['startDate']),
        endDate: _tryParseDate(json['endDate']),
        modality: json['modality'] == null
            ? null
            : Modality.fromJson(json['modality'] as String),
        gender: json['gender'] as String?,
        ageGroup: json['ageGroup'] as String?,
        groupingType: GroupingType.tryFromJson(json['groupingType'] as String?),
        createdBy: json['createdBy'] as String?,
        createdAt: _tryParseDate(json['createdAt']),
        updatedAt: _tryParseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.toJson(),
        'season': season,
        'tournamentFormat': tournamentFormat.toJson(),
        if (organizationId != null) 'organizationId': organizationId,
        if (organizationName != null) 'organizationName': organizationName,
        if (description != null) 'description': description,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        if (modality != null) 'modality': modality!.toJson(),
        if (gender != null) 'gender': gender,
        if (ageGroup != null) 'ageGroup': ageGroup,
        if (createdBy != null) 'createdBy': createdBy,
      };

  Competition copyWith({
    String? id,
    String? name,
    CompetitionStatus? status,
    String? season,
    TournamentFormat? tournamentFormat,
    String? organizationId,
    String? organizationName,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    Modality? modality,
    String? gender,
    String? ageGroup,
    String? createdBy,
  }) {
    return Competition(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      season: season ?? this.season,
      tournamentFormat: tournamentFormat ?? this.tournamentFormat,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      modality: modality ?? this.modality,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Nome de exibição concatenado com características da competição:
  /// Nome do campeonato + modalidade + gênero.
  String get displayName {
    final parts = <String>[name];
    final details = <String>[
      if (modality != null) modality!.label,
      if (gender != null && gender!.isNotEmpty)
        (gender == 'male'
            ? 'Masculino'
            : gender == 'female'
                ? 'Feminino'
                : 'Misto'),
    ];
    if (details.isNotEmpty) {
      parts.add(details.join(' - '));
    }
    return parts.join(' • ');
  }
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
