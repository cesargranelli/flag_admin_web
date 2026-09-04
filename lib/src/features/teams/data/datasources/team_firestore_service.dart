import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_service.dart';

/// Modelo de time.
class Team {
  final String id;
  final String organizationId;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final String? sport;
  final String? status;
  final DateTime? createdAt;
  final String? organizationName;

  const Team({
    required this.id,
    required this.organizationId,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.sport,
    this.status,
    this.createdAt,
    this.organizationName,
  });

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      organizationId: data['organizationId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      shortName: data['shortName'] as String?,
      logoUrl: data['logoUrl'] as String?,
      sport: data['sport'] as String?,
      status: data['status'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      organizationName: data['organizationName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizationId': organizationId,
      'name': name,
      if (shortName != null) 'shortName': shortName,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (sport != null) 'sport': sport,
      if (status != null) 'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      if (organizationName != null) 'organizationName': organizationName,
    };
  }
}

/// Serviço de times.
class TeamFirestoreService extends FirestoreService<Team> {
  @override
  String get collectionName => 'teams';

  @override
  Team fromFirestore(DocumentSnapshot doc) => Team.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Team item) => item.toFirestore();

  /// Lista times por organização.
  Future<List<Team>> listByOrganization(String organizationId) {
    return listWhere('organizationId', organizationId);
  }
}

