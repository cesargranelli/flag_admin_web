/// Rótulo do agrupamento da estrutura da competição (#308).
///
/// Conferências, Divisões e Grupos são aspectos opcionais da competição
/// para agrupamento, classificação e cruzamento de jogos.
enum GroupingType {
  none,
  groups,
  conferences,
  conferencesAndDivisions,
  divisions;

  static GroupingType fromJson(String value) => switch (value) {
        'NONE' => GroupingType.none,
        'GROUPS' => GroupingType.groups,
        'CONFERENCES' => GroupingType.conferences,
        'CONFERENCES_AND_DIVISIONS' => GroupingType.conferencesAndDivisions,
        'DIVISIONS' => GroupingType.divisions,
        _ => GroupingType.none,
      };

  static GroupingType? tryFromJson(String? value) {
    if (value == null) return null;
    try {
      return fromJson(value);
    } catch (_) {
      return null;
    }
  }

  String toJson() => switch (this) {
        GroupingType.none => 'NONE',
        GroupingType.groups => 'GROUPS',
        GroupingType.conferences => 'CONFERENCES',
        GroupingType.conferencesAndDivisions => 'CONFERENCES_AND_DIVISIONS',
        GroupingType.divisions => 'DIVISIONS',
      };

  /// Rótulo amigável em pt-BR.
  String get label => switch (this) {
        GroupingType.none => 'Sem Agrupamento (Tabela Única)',
        GroupingType.groups => 'Grupos (Grupo A, Grupo B...)',
        GroupingType.conferences => 'Conferências (Leste, Oeste...)',
        GroupingType.conferencesAndDivisions => 'Conferências e Divisões',
        GroupingType.divisions => 'Divisões',
      };
}
