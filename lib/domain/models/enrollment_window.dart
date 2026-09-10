/// Modelo de Janela de Inscrição de Equipes em Competição (ADR-001 / Domain).
class EnrollmentWindow {
  final String id;
  final String competitionId;
  final String competitionName;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isOpen;
  final String? instructions;
  final DateTime? createdAt;
  final String? createdBy;

  const EnrollmentWindow({
    required this.id,
    required this.competitionId,
    required this.competitionName,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isOpen,
    this.instructions,
    this.createdAt,
    this.createdBy,
  });

  factory EnrollmentWindow.fromJson(Map<String, dynamic> json) {
    return EnrollmentWindow(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      competitionName: json['competitionName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'OPEN',
      isOpen: json['isOpen'] as bool? ?? false,
      instructions: json['instructions'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
    );
  }
}
