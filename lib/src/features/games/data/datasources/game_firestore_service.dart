import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Modelo de jogo.
class Game {
  final String id;
  final String competitionId;
  final String? roundId;
  final String? venueId;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime? scheduledAt;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final int? homeScore;
  final int? awayScore;
  final String? status;
  final String? notes;
  final DateTime? createdAt;
  final String? competitionName;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? venueName;

  const Game({
    required this.id,
    required this.competitionId,
    this.roundId,
    this.venueId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.scheduledAt,
    this.actualStartTime,
    this.actualEndTime,
    this.homeScore,
    this.awayScore,
    this.status,
    this.notes,
    this.createdAt,
    this.competitionName,
    this.homeTeamName,
    this.awayTeamName,
    this.venueName,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      competitionId: data['competitionId'] as String? ?? '',
      roundId: data['roundId'] as String?,
      venueId: data['venueId'] as String?,
      homeTeamId: data['homeTeamId'] as String? ?? '',
      awayTeamId: data['awayTeamId'] as String? ?? '',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      actualStartTime: (data['actualStartTime'] as Timestamp?)?.toDate(),
      actualEndTime: (data['actualEndTime'] as Timestamp?)?.toDate(),
      homeScore: data['homeScore'] as int?,
      awayScore: data['awayScore'] as int?,
      status: data['status'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      competitionName: data['competitionName'] as String?,
      homeTeamName: data['homeTeamName'] as String?,
      awayTeamName: data['awayTeamName'] as String?,
      venueName: data['venueName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'competitionId': competitionId,
      if (roundId != null) 'roundId': roundId,
      if (venueId != null) 'venueId': venueId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
      if (actualStartTime != null)
        'actualStartTime': Timestamp.fromDate(actualStartTime!),
      if (actualEndTime != null)
        'actualEndTime': Timestamp.fromDate(actualEndTime!),
      if (homeScore != null) 'homeScore': homeScore,
      if (awayScore != null) 'awayScore': awayScore,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      if (competitionName != null) 'competitionName': competitionName,
      if (homeTeamName != null) 'homeTeamName': homeTeamName,
      if (awayTeamName != null) 'awayTeamName': awayTeamName,
      if (venueName != null) 'venueName': venueName,
    };
  }
}

/// Serviço de jogos.
class GameFirestoreService extends FirestoreService<Game> {
  @override
  String get collectionName => 'games';

  @override
  Game fromFirestore(DocumentSnapshot doc) => Game.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Game item) => item.toFirestore();

  /// Lista jogos por competição.
  Future<List<Game>> listByCompetition(String competitionId) {
    return listWhere('competitionId', competitionId);
  }

  /// Lista jogos por time.
  Future<List<Game>> listByTeam(String teamId) async {
    final homeGames = await collection
        .where('homeTeamId', isEqualTo: teamId)
        .orderBy('scheduledAt', descending: true)
        .limit(20)
        .get();
    final awayGames = await collection
        .where('awayTeamId', isEqualTo: teamId)
        .orderBy('scheduledAt', descending: true)
        .limit(20)
        .get();
    final allGames = [...homeGames.docs, ...awayGames.docs];
    return allGames.map((doc) => fromFirestore(doc)).toList();
  }

  /// Lista jogos ativos.
  Future<List<Game>> listActive() async {
    final snapshot = await collection
        .where('status', whereIn: ['SCHEDULED', 'IN_PROGRESS'])
        .orderBy('scheduledAt')
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Atualiza status do jogo.
  Future<void> updateStatus(String gameId, String status) async {
    await collection.doc(gameId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Atualiza placar do jogo.
  Future<void> updateScore(
    String gameId, {
    required int homeScore,
    required int awayScore,
  }) async {
    await collection.doc(gameId).update({
      'homeScore': homeScore,
      'awayScore': awayScore,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Check-ins ─────────────────────────────────────────────────────

  /// Faz check-in de atleta no jogo.
  Future<void> checkIn(String gameId, Map<String, dynamic> checkIn) async {
    await collection
        .doc(gameId)
        .collection('checkins')
        .doc(checkIn['personId'])
        .set(checkIn);
  }

  /// Lista check-ins de um jogo.
  Future<List<Map<String, dynamic>>> listCheckIns(String gameId) async {
    final snapshot = await collection
        .doc(gameId)
        .collection('checkins')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // ── Score Events ──────────────────────────────────────────────────

  /// Registra evento de placar.
  Future<void> addScoreEvent(String gameId, Map<String, dynamic> event) async {
    await collection.doc(gameId).collection('scoreEvents').add(event);
  }

  /// Lista eventos de placar.
  Future<List<Map<String, dynamic>>> listScoreEvents(String gameId) async {
    final snapshot = await collection
        .doc(gameId)
        .collection('scoreEvents')
        .orderBy('timestamp')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Escuta jogos ativos em tempo real.
  Stream<List<Game>> streamActive() {
    return collection
        .where('status', whereIn: ['SCHEDULED', 'IN_PROGRESS'])
        .orderBy('scheduledAt')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }
}
