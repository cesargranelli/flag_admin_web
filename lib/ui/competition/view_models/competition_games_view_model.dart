import 'package:flag_admin_web/data/api/api_client.dart';
import 'package:flag_admin_web/data/repositories/competition_team_repository.dart';
import 'package:flag_admin_web/data/repositories/game_repository.dart';
import 'package:flag_admin_web/data/repositories/round_repository.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';
import 'package:flag_admin_web/domain/enums/game_status.dart';
import 'package:flag_admin_web/domain/enums/round_type.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/models/competition_team.dart';
import 'package:flag_admin_web/domain/models/game.dart';
import 'package:flag_admin_web/domain/models/round.dart';
import 'package:flag_admin_web/domain/models/team.dart';
import 'package:flag_admin_web/domain/models/venue.dart';
import 'package:flutter/foundation.dart';

/// ViewModel da tela de Tabelamento e Agendamento de Jogos da Competição.
class CompetitionGamesViewModel extends ChangeNotifier {
  final GameRepository _gameRepo;
  final RoundRepository _roundRepo;
  final CompetitionTeamRepository _teamRepo;
  final VenueRepository _venueRepo;
  final ApiClient _client;
  final String competitionId;
  final Competition? competition;

  CompetitionGamesViewModel({
    required GameRepository gameRepo,
    required RoundRepository roundRepo,
    required CompetitionTeamRepository teamRepo,
    required VenueRepository venueRepo,
    required ApiClient client,
    required this.competitionId,
    this.competition,
  }) : _gameRepo = gameRepo,
       _roundRepo = roundRepo,
       _teamRepo = teamRepo,
       _venueRepo = venueRepo,
       _client = client;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  String? _actionInProgressId;

  String? get actionInProgressId => _actionInProgressId;

  List<Round> _rounds = [];

  List<Round> get rounds => _rounds;

  List<Game> _games = [];

  List<Game> get games => _games;

  List<CompetitionTeam> _teams = [];

  List<CompetitionTeam> get teams => _teams;

  /// Mapeia teamId → logoUrl a partir da lista completa de Times.
  Map<String, String?> _teamLogos = {};

  Map<String, String?> get teamLogos => _teamLogos;

  List<Venue> _venues = [];

  List<Venue> get venues => _venues;

  String? _selectedRoundId;

  String? get selectedRoundId => _selectedRoundId;

  GameStatus? _selectedStatus;

  GameStatus? get selectedStatus => _selectedStatus;

  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  void setSelectedRoundId(String? roundId) {
    _selectedRoundId = roundId;
    notifyListeners();
  }

  void setSelectedStatus(GameStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Game> get filteredGames {
    return _games.where((g) {
      if (_selectedRoundId != null && g.roundId != _selectedRoundId) {
        return false;
      }
      if (_selectedStatus != null && g.status != _selectedStatus) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final home = (g.homeTeamName ?? '').toLowerCase();
        final away = (g.awayTeamName ?? '').toLowerCase();
        final venue = (g.venueName ?? '').toLowerCase();
        if (!home.contains(q) && !away.contains(q) && !venue.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<void> load({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _roundRepo.getRoundsByCompetition(
          competitionId,
          forceRefresh: forceRefresh,
        ),
        _gameRepo.getGamesByCompetition(
          competitionId,
          forceRefresh: forceRefresh,
        ),
        _teamRepo.getTeamsByCompetition(
          competitionId,
          forceRefresh: forceRefresh,
        ),
        _venueRepo.getVenues(forceRefresh: forceRefresh),
        _client
            .getList('/api/v1/teams', Team.fromJson)
            .catchError((_) => <Team>[]),
      ]);

      _rounds = (results[0] as List<Round>).toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      _games = results[1] as List<Game>;
      final rawTeams = results[2] as List<CompetitionTeam>;
      _venues = results[3] as List<Venue>;
      final allTeams = results[4] as List<Team>;

      final teamClubMap = <String, String>{};
      _teamLogos = {for (final t in allTeams) if (t.logoUrl != null && t.logoUrl!.isNotEmpty) t.id: t.logoUrl!};
      for (final t in allTeams) {
        if (t.clubName != null && t.clubName!.trim().isNotEmpty) {
          teamClubMap[t.id] = t.clubName!.trim();
        }
      }

      _teams = rawTeams.map((ct) {
        if (ct.clubName != null && ct.clubName!.trim().isNotEmpty) {
          return ct;
        }
        final club = teamClubMap[ct.teamId];
        if (club != null) {
          return ct.copyWith(clubName: club);
        }
        return ct;
      }).toList();
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados do tabelamento: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRound({
    required int number,
    required String name,
    required RoundType type,
  }) async {
    try {
      _actionInProgressId = 'new_round';
      notifyListeners();

      await _roundRepo.createRound(
        competitionId: competitionId,
        number: number,
        name: name,
        type: type,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar rodada: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }

  Future<bool> updateRound({
    required String id,
    required int number,
    required String name,
    required RoundType type,
  }) async {
    try {
      _actionInProgressId = id;
      notifyListeners();

      await _roundRepo.updateRound(
        id,
        competitionId: competitionId,
        number: number,
        name: name,
        type: type,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar rodada: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }

  Future<bool> createGame({
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) async {
    try {
      _actionInProgressId = 'new_game';
      notifyListeners();

      await _gameRepo.createGame(
        competitionId: competitionId,
        roundId: roundId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        venueId: venueId,
        scheduledAt: scheduledAt,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao agendar jogo: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }

  Future<bool> updateGame({
    required String id,
    required String roundId,
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime scheduledAt,
  }) async {
    try {
      _actionInProgressId = id;
      notifyListeners();

      await _gameRepo.updateGame(
        id,
        competitionId: competitionId,
        roundId: roundId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        venueId: venueId,
        scheduledAt: scheduledAt,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar jogo: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }

  Future<bool> updateGameStatus({
    required String id,
    required GameStatus status,
  }) async {
    try {
      _actionInProgressId = id;
      notifyListeners();

      await _gameRepo.updateStatus(
        id,
        competitionId: competitionId,
        status: status,
      );
      await load(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar status do jogo: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _actionInProgressId = null;
      notifyListeners();
    }
  }
}
