import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_service.dart';

/// Modelo de pessoa.
class Person {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? gender;
  final DateTime? birthDate;
  final String? computedAgeGroup;
  final List<String> roles;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Person({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.gender,
    this.birthDate,
    this.computedAgeGroup,
    this.roles = const [],
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Person.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Person(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      gender: data['gender'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      computedAgeGroup: data['computedAgeGroup'] as String?,
      roles: List<String>.from(data['roles'] ?? []),
      status: data['status'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
      if (computedAgeGroup != null) 'computedAgeGroup': computedAgeGroup,
      'roles': roles,
      if (status != null) 'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Calcula ageGroup a partir de birthDate.
  String? calculateAgeGroup() {
    if (birthDate == null) return null;
    final now = DateTime.now();
    final age = now.year - birthDate!.year -
        (now.month < birthDate!.month ||
                (now.month == birthDate!.month && now.day < birthDate!.day)
            ? 1
            : 0);
    if (age <= 6) return 'U6';
    if (age <= 8) return 'U8';
    if (age <= 10) return 'U10';
    if (age <= 12) return 'U12';
    if (age <= 14) return 'U14';
    if (age <= 16) return 'U16';
    if (age <= 18) return 'U18';
    if (age <= 20) return 'U20';
    return 'OPEN';
  }
}

/// Serviço de pessoas.
class PersonFirestoreService extends FirestoreService<Person> {
  @override
  String get collectionName => 'persons';

  @override
  Person fromFirestore(DocumentSnapshot doc) => Person.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Person item) => item.toFirestore();

  /// Lista pessoas por role.
  Future<List<Person>> listByRole(String role) async {
    final snapshot = await collection
        .where('roles', arrayContains: role)
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }
}
