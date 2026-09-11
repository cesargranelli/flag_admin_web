enum OrganizationType {
  federation,
  league,
  association;

  static OrganizationType fromJson(String value) => switch (value) {
        'FEDERATION' => OrganizationType.federation,
        'LEAGUE' => OrganizationType.league,
        'ASSOCIATION' => OrganizationType.association,
        _ => throw FormatException('Tipo de organização desconhecido: $value'),
      };

  String toJson() => switch (this) {
        OrganizationType.federation => 'FEDERATION',
        OrganizationType.league => 'LEAGUE',
        OrganizationType.association => 'ASSOCIATION',
      };

  /// Nome amigável em português para exibição.
  String get label => switch (this) {
        OrganizationType.federation => 'Federação',
        OrganizationType.league => 'Liga',
        OrganizationType.association => 'Associação',
      };
}
