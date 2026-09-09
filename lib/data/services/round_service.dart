import 'package:flag_admin_web/domain/models/round.dart';

abstract class RoundService {
  Future<List<Round>> listByCompetition(String competitionId);
  Future<Round> getById(String id);
  Future<Round> create({
    required String competitionId,
    required int number,
    required String name,
    required RoundType type,
  });
  Future<Round> update(
    String id, {
    required String competitionId,
    required int number,
    required String name,
    required RoundType type,
  });
}
