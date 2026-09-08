/// Status da inscrição da equipe na competição.
enum CompetitionTeamStatus {
  pending,
  approved,
  rejected;

  static CompetitionTeamStatus fromJson(String value) => switch (value.toUpperCase()) {
        'APPROVED' => CompetitionTeamStatus.approved,
        'REJECTED' => CompetitionTeamStatus.rejected,
        _ => CompetitionTeamStatus.pending,
      };

  String toJson() => switch (this) {
        CompetitionTeamStatus.pending => 'PENDING',
        CompetitionTeamStatus.approved => 'APPROVED',
        CompetitionTeamStatus.rejected => 'REJECTED',
      };

  String get label => switch (this) {
        CompetitionTeamStatus.pending => 'Pendente',
        CompetitionTeamStatus.approved => 'Homologado',
        CompetitionTeamStatus.rejected => 'Rejeitado',
      };
}
