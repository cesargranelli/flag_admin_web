/// Rótulo do agrupamento da estrutura da competição (#308).
///
/// Conferências (com ou sem Divisões) e Grupos são modelos mutuamente
/// exclusivos para agrupamento, classificação e cruzamento de jogos.
enum GroupingType {
  none,
  groups,
  conferences;

  static GroupingType fromJson(String value) => switch (value) {
        'NONE' => GroupingType.none,
        'GROUPS' => GroupingType.groups,
        'CONFERENCES' || 'CONFERENCES_AND_DIVISIONS' || 'DIVISIONS' =>
          GroupingType.conferences,
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
      };

  /// Rótulo amigável em pt-BR.
  String get label => switch (this) {
        GroupingType.none => 'Sem Agrupamento (Tabela Única)',
        GroupingType.groups => 'Fase de Grupos',
        GroupingType.conferences => 'Conferências & Divisões',
      };
}
