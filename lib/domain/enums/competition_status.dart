enum CompetitionStatus {
  draft,
  registrationOpen,
  registrationClosed,
  ongoing,
  published,
  finished,
  disabled;

  static CompetitionStatus fromJson(String value) => switch (value) {
        'DRAFT' => CompetitionStatus.draft,
        'REGISTRATION_OPEN' => CompetitionStatus.registrationOpen,
        'REGISTRATION_CLOSED' => CompetitionStatus.registrationClosed,
        'ONGOING' => CompetitionStatus.ongoing,
        'PUBLISHED' => CompetitionStatus.published,
        'FINISHED' => CompetitionStatus.finished,
        'DISABLED' => CompetitionStatus.disabled,
        _ => CompetitionStatus.draft,
      };

  String toJson() => switch (this) {
        CompetitionStatus.draft => 'DRAFT',
        CompetitionStatus.registrationOpen => 'REGISTRATION_OPEN',
        CompetitionStatus.registrationClosed => 'REGISTRATION_CLOSED',
        CompetitionStatus.ongoing => 'ONGOING',
        CompetitionStatus.published => 'PUBLISHED',
        CompetitionStatus.finished => 'FINISHED',
        CompetitionStatus.disabled => 'DISABLED',
      };

  /// Nome amigável em português para exibição.
  String get label => switch (this) {
        CompetitionStatus.draft => 'Rascunho',
        CompetitionStatus.registrationOpen => 'Inscrições Abertas',
        CompetitionStatus.registrationClosed => 'Inscrições Encerradas',
        CompetitionStatus.ongoing => 'Em Andamento',
        CompetitionStatus.published => 'Publicado',
        CompetitionStatus.finished => 'Encerrado',
        CompetitionStatus.disabled => 'Desativado',
      };
}
