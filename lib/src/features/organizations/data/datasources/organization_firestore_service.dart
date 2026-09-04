import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_service.dart';

/// Modelo de organização.
class Organization {
  final String id;
  final String name;
  final String? tradeName;
  final String? type;
  final String? document;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? status;
  final DateTime? createdAt;

  const Organization({
    required this.id,
    required this.name,
    this.tradeName,
    this.type,
    this.document,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.status,
    this.createdAt,
  });

  factory Organization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Organization(
      id: doc.id,
      name: data['name'] as String? ?? '',
      tradeName: data['tradeName'] as String?,
      type: data['type'] as String?,
      document: data['document'] as String?,
      logoUrl: data['logoUrl'] as String?,
      primaryColor: data['primaryColor'] as String?,
      secondaryColor: data['secondaryColor'] as String?,
      status: data['status'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (tradeName != null) 'tradeName': tradeName,
      if (type != null) 'type': type,
      if (document != null) 'document': document,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (primaryColor != null) 'primaryColor': primaryColor,
      if (secondaryColor != null) 'secondaryColor': secondaryColor,
      if (status != null) 'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Serviço de organizações.
class OrganizationFirestoreService extends FirestoreService<Organization> {
  @override
  String get collectionName => 'organizations';

  @override
  Organization fromFirestore(DocumentSnapshot doc) =>
      Organization.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Organization item) => item.toFirestore();
}

