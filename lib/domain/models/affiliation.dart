/// Modelo de Filiacao de Agremiacao a Organizacao (ADR-001 / Domain).
class Affiliation {
  final String id;
  final String institutionId;
  final String institutionName;
  final String? institutionType;
  final String? institutionLogoUrl;
  final String organizationId;
  final String organizationName;
  final String? organizationType;
  final String season;
  final String status;
  final String? rejectionReason;
  final DateTime? requestedAt;
  final String? requestedBy;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const Affiliation({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    this.institutionType,
    this.institutionLogoUrl,
    required this.organizationId,
    required this.organizationName,
    this.organizationType,
    required this.season,
    required this.status,
    this.rejectionReason,
    this.requestedAt,
    this.requestedBy,
    this.reviewedAt,
    this.reviewedBy,
  });

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';

  factory Affiliation.fromJson(Map<String, dynamic> json) {
    return Affiliation(
      id: json['id'] as String,
      institutionId: json['institutionId'] as String,
      institutionName: json['institutionName'] as String? ?? '',
      institutionType: json['institutionType'] as String?,
      institutionLogoUrl: json['institutionLogoUrl'] as String?,
      organizationId: json['organizationId'] as String,
      organizationName: json['organizationName'] as String? ?? '',
      organizationType: json['organizationType'] as String?,
      season: json['season'] as String? ?? '2026',
      status: json['status'] as String? ?? 'PENDING',
      rejectionReason: json['rejectionReason'] as String?,
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'] as String)
          : null,
      requestedBy: json['requestedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      reviewedBy: json['reviewedBy'] as String?,
    );
  }
}
