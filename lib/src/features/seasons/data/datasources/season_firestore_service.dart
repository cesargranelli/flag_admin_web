import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_service.dart';

/// Modelo de temporada.
class Season {
  final String id;
  final String organizationId;
  final String name;
  final String sport;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final DateTime? createdAt;

  const Season({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.sport,
    this.startDate,
    this.endDate,
    this.status,
    this.createdAt,
  });

  factory Season.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Season(
      id: doc.id,
      organizationId: data['organizationId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      sport: data['sport'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      status: data['status'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizationId': organizationId,
      'name': name,
      'sport': sport,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (status != null) 'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Serviço de temporadas.
class SeasonFirestoreService extends FirestoreService<Season> {
  @override
  String get collectionName => 'seasons';

  @override
  Season fromFirestore(DocumentSnapshot doc) => Season.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Season item) => item.toFirestore();

  /// Lista temporadas por organização.
  Future<List<Season>> listByOrganization(String organizationId) {
    return listWhere('organizationId', organizationId);
  }
}

