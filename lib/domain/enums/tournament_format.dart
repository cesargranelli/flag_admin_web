/// Formato de disputa do torneio/campeonato.
enum TournamentFormat {
  roundRobin,
  playoffs,
  groupsAndPlayoffs;

  static TournamentFormat fromJson(String value) => switch (value) {
        'ROUND_ROBIN' => TournamentFormat.roundRobin,
        'PLAYOFFS' => TournamentFormat.playoffs,
        'GROUPS_AND_PLAYOFFS' => TournamentFormat.groupsAndPlayoffs,
        _ => TournamentFormat.roundRobin,
      };

  static TournamentFormat? tryFromJson(String? value) {
    if (value == null) return null;
    try {
      return fromJson(value);
    } catch (_) {
      return null;
    }
  }

  String toJson() => switch (this) {
        TournamentFormat.roundRobin => 'ROUND_ROBIN',
        TournamentFormat.playoffs => 'PLAYOFFS',
        TournamentFormat.groupsAndPlayoffs => 'GROUPS_AND_PLAYOFFS',
      };

  /// Rótulo amigável em português (exclusivo futebol americano).
  String get label => switch (this) {
        TournamentFormat.roundRobin => 'Pontos Corridos',
        TournamentFormat.playoffs => 'Playoffs',
        TournamentFormat.groupsAndPlayoffs => 'Grupos + Playoffs',
      };
}
