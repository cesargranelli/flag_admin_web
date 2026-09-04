import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_service.dart';

/// Modelo de venue.
class Venue {
  final String id;
  final String name;
  final String? logoUrl;
  final Map<String, dynamic>? address;
  final String? mapsUrl;
  final DateTime? createdAt;

  const Venue({
    required this.id,
    required this.name,
    this.logoUrl,
    this.address,
    this.mapsUrl,
    this.createdAt,
  });

  factory Venue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Venue(
      id: doc.id,
      name: data['name'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as Map<String, dynamic>?,
      mapsUrl: data['mapsUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (address != null) 'address': address,
      if (mapsUrl != null) 'mapsUrl': mapsUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Serviço de venues.
class VenueFirestoreService extends FirestoreService<Venue> {
  @override
  String get collectionName => 'venues';

  @override
  Venue fromFirestore(DocumentSnapshot doc) => Venue.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Venue item) => item.toFirestore();
}
