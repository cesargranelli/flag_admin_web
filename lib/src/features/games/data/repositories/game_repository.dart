import '../datasources/game_firestore_service.dart';

/// Repository para jogos.
///
/// Abstrai a fonte de dados (Firestore) da lógica de negócio.
class GameRepository {
  final GameFirestoreService _datasource;

  GameRepository(this._datasource);

  /// Lista todos os jogos.
  Future<List<Game>> getAll() async {
    return await _datasource.list();
  }

  /// Busca jogo por ID.
  Future<Game?> getById(String id) async {
    return await _datasource.getById(id);
  }

  /// Cria novo jogo.
  Future<Game> create(Game game) async {
    return await _datasource.create(game);
  }

  /// Atualiza jogo existente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _datasource.update(id, data);
  }

  /// Remove jogo.
  Future<void> delete(String id) async {
    await _datasource.delete(id);
  }

  /// Escuta mudanças em tempo real.
  Stream<List<Game>> watchAll() {
    return _datasource.streamList();
  }

  /// Lista jogos por competição.
  Future<List<Game>> getByCompetition(String competitionId) {
    return _datasource.listByCompetition(competitionId);
  }

  /// Escuta jogos por competição.
  Stream<List<Game>> watchByCompetition(String competitionId) {
    return _datasource.streamWhere('competitionId', competitionId);
  }

  /// Lista jogos ativos (agendados ou em andamento).
  Future<List<Game>> getActive() async {
    return await _datasource.listActive();
  }

  /// Escuta jogos ativos em tempo real.
  Stream<List<Game>> watchActive() {
    return _datasource.streamActive();
  }
}