import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_service.dart';

/// Modelo de competição.
class Competition {
  final String id;
  final String? seasonId;
  final String organizationId;
  final String name;
  final String sport;
  final String? modality;
  final String? gender;
  final String? ageGroup;
  final String? groupingType;
  final String? venueId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final Map<String, dynamic>? eligibilityRules;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? organizationName;
  final String? seasonName;
  final String? venueName;

  const Competition({
    required this.id,
    this.seasonId,
    required this.organizationId,
    required this.name,
    required this.sport,
    this.modality,
    this.gender,
    this.ageGroup,
    this.groupingType,
    this.venueId,
    this.startDate,
    this.endDate,
    this.status,
    this.eligibilityRules,
    this.createdAt,
    this.updatedAt,
    this.organizationName,
    this.seasonName,
    this.venueName,
  });

  factory Competition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Competition(
      id: doc.id,
      seasonId: data['seasonId'] as String?,
      organizationId: data['organizationId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      sport: data['sport'] as String? ?? '',
      modality: data['modality'] as String?,
      gender: data['gender'] as String?,
      ageGroup: data['ageGroup'] as String?,
      groupingType: data['groupingType'] as String?,
      venueId: data['venueId'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      status: data['status'] as String?,
      eligibilityRules: data['eligibilityRules'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      organizationName: data['organizationName'] as String?,
      seasonName: data['seasonName'] as String?,
      venueName: data['venueName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (seasonId != null) 'seasonId': seasonId,
      'organizationId': organizationId,
      'name': name,
      'sport': sport,
      if (modality != null) 'modality': modality,
      if (gender != null) 'gender': gender,
      if (ageGroup != null) 'ageGroup': ageGroup,
      if (groupingType != null) 'groupingType': groupingType,
      if (venueId != null) 'venueId': venueId,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (status != null) 'status': status,
      if (eligibilityRules != null) 'eligibilityRules': eligibilityRules,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (organizationName != null) 'organizationName': organizationName,
      if (seasonName != null) 'seasonName': seasonName,
      if (venueName != null) 'venueName': venueName,
    };
  }
}

/// Serviço de competições.
class CompetitionFirestoreService extends FirestoreService<Competition> {
  @override
  String get collectionName => 'competitions';

  @override
  Competition fromFirestore(DocumentSnapshot doc) =>
      Competition.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Competition item) => item.toFirestore();

  /// Lista competições por organização.
  Future<List<Competition>> listByOrganization(String organizationId) {
    return listWhere('organizationId', organizationId);
  }

  /// Lista competições por season.
  Future<List<Competition>> listBySeason(String seasonId) {
    return listWhere('seasonId', seasonId);
  }

  /// Lista competições por status.
  Future<List<Competition>> listByStatus(String status) {
    return listWhere('status', status);
  }

  // ── Groups ────────────────────────────────────────────────────────

  /// Lista grupos de uma competição.
  Future<List<Map<String, dynamic>>> listGroups(String competitionId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .collection('groups')
        .orderBy('sortOrder')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Cria grupo em uma competição.
  Future<void> createGroup(
    String competitionId,
    Map<String, dynamic> group,
  ) async {
    await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .collection('groups')
        .add(group);
  }

  // ── Rounds ────────────────────────────────────────────────────────

  /// Lista rodadas de uma competição.
  Future<List<Map<String, dynamic>>> listRounds(String competitionId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .collection('rounds')
        .orderBy('number')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Cria rodada em uma competição.
  Future<void> createRound(
    String competitionId,
    Map<String, dynamic> round,
  ) async {
    await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .collection('rounds')
        .add(round);
  }

  // ── Competition Teams ─────────────────────────────────────────────

  /// Inscreve time em uma competição.
  Future<void> enrollTeam(
    String competitionId,
    Map<String, dynamic> compTeam,
  ) async {
    await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .collection('competitionTeams')
        .doc(compTeam['teamId'])
        .set(compTeam);
  }

  /// Lista times inscritos em uma competição.
  Future<List<Map<String, dynamic>>> listEnrolledTeams(
    String competitionId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .collection('competitionTeams')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // ── Roster ────────────────────────────────────────────────────────

  /// Adiciona atleta ao elenco.
  Future<void> addRosterEntry(
    String competitionId,
    Map<String, dynamic> entry,
  ) async {
    await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .collection('roster')
        .add(entry);
  }

  /// Lista elenco de uma competição.
  Future<List<Map<String, dynamic>>> listRoster(String competitionId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .collection('roster')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
