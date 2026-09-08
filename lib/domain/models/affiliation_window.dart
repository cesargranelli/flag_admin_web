/// Modelo de Janela / Periodo de Filiacao (ADR-001 / Domain).
class AffiliationWindow {
  final String id;
  final String organizationId;
  final String organizationName;
  final String season;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isOpen;
  final String? instructions;
  final DateTime? createdAt;
  final String? createdBy;

  const AffiliationWindow({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.season,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isOpen,
    this.instructions,
    this.createdAt,
    this.createdBy,
  });

  factory AffiliationWindow.fromJson(Map<String, dynamic> json) {
    return AffiliationWindow(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      organizationName: json['organizationName'] as String? ?? '',
      season: json['season'] as String? ?? '2026',
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
