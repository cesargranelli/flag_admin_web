/// Configuração estruturada e tipada dos agrupamentos da competição.
class GroupingConfig {
  final List<CompetitionGroupConfig> groups;
  final List<CompetitionConferenceConfig> conferences;

  const GroupingConfig({
    this.groups = const [],
    this.conferences = const [],
  });

  factory GroupingConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GroupingConfig();

    final rawGroups = json['groups'] as List<dynamic>? ?? [];
    final rawConferences = json['conferences'] as List<dynamic>? ?? [];

    return GroupingConfig(
      groups: rawGroups
          .map((g) => CompetitionGroupConfig.fromJson(g as Map<String, dynamic>))
          .toList(),
      conferences: rawConferences
          .map((c) => CompetitionConferenceConfig.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (groups.isNotEmpty)
          'groups': groups.map((g) => g.toJson()).toList(),
        if (conferences.isNotEmpty)
          'conferences': conferences.map((c) => c.toJson()).toList(),
      };

  GroupingConfig copyWith({
    List<CompetitionGroupConfig>? groups,
    List<CompetitionConferenceConfig>? conferences,
  }) {
    return GroupingConfig(
      groups: groups ?? this.groups,
      conferences: conferences ?? this.conferences,
    );
  }
}

/// Representa um grupo nomeado (ex: "Grupo A", "Grupo dos Campeões").
class CompetitionGroupConfig {
  final String id;
  final String name;

  const CompetitionGroupConfig({
    required this.id,
    required this.name,
  });

  factory CompetitionGroupConfig.fromJson(Map<String, dynamic> json) =>
      CompetitionGroupConfig(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

/// Representa uma conferência nomeada (ex: "Conferência Americana")
/// que pode opcionalmente possuir divisões associadas.
class CompetitionConferenceConfig {
  final String id;
  final String name;
  final List<CompetitionDivisionConfig> divisions;

  const CompetitionConferenceConfig({
    required this.id,
    required this.name,
    this.divisions = const [],
  });

  factory CompetitionConferenceConfig.fromJson(Map<String, dynamic> json) {
    final rawDivs = json['divisions'] as List<dynamic>? ?? [];
    return CompetitionConferenceConfig(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      divisions: rawDivs
          .map((d) => CompetitionDivisionConfig.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'divisions': divisions.map((d) => d.toJson()).toList(),
      };

  CompetitionConferenceConfig copyWith({
    String? id,
    String? name,
    List<CompetitionDivisionConfig>? divisions,
  }) {
    return CompetitionConferenceConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      divisions: divisions ?? this.divisions,
    );
  }
}

/// Representa uma divisão subordinada a uma conferência (ex: "Divisão Leste").
class CompetitionDivisionConfig {
  final String id;
  final String name;

  const CompetitionDivisionConfig({
    required this.id,
    required this.name,
  });

  factory CompetitionDivisionConfig.fromJson(Map<String, dynamic> json) =>
      CompetitionDivisionConfig(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
