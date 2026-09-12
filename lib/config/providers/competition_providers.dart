/// Competition domain providers (services, repositories, viewmodels, list providers).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/services/api_competition_team_service.dart';
import 'package:flag_admin_web/data/api/api.dart';
import 'package:flag_admin_web/data/services/competition_service.dart';
import 'package:flag_admin_web/data/services/competition_team_service.dart';
import 'package:flag_admin_web/data/repositories/competition_repository.dart';
import 'package:flag_admin_web/data/repositories/competition_team_repository.dart';
import 'package:flag_admin_web/domain/models/enrollment_window.dart';
import 'package:flag_admin_web/config/domain_imports.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_create_view_model.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_detail_view_model.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_edit_view_model.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_games_view_model.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_list_view_model.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_teams_view_model.dart';

import 'base_providers.dart';
import 'game_providers.dart';
import 'round_providers.dart';
import 'venue_providers.dart';

/// Serviço de competições (REST).
final competitionServiceProvider = Provider<CompetitionService>(
  (ref) => ApiCompetitionService(ref.watch(apiClientProvider)),
);

/// Repository de competições (Single Source of Truth, Caching).
final competitionRepositoryProvider = Provider<CompetitionRepository>(
  (ref) =>
      CompetitionRepository(service: ref.watch(competitionServiceProvider)),
);

/// ViewModel de listagem de competições.
final competitionListViewModelProvider =
    ChangeNotifierProvider<CompetitionListViewModel>(
      (ref) => CompetitionListViewModel(
        repository: ref.watch(competitionRepositoryProvider),
      ),
    );

/// ViewModel de detalhes de competição (1:1 com CompetitionDetailScreen).
final competitionDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<CompetitionDetailViewModel, String>(
      (ref, id) => CompetitionDetailViewModel(
        repository: ref.watch(competitionRepositoryProvider),
        competitionId: id,
      ),
    );

/// Lista de janelas de inscrição de equipes abertas no momento (para qualquer competição).
final openEnrollmentWindowsProvider =
    FutureProvider.autoDispose<List<EnrollmentWindow>>(
      (ref) =>
          ref.watch(competitionRepositoryProvider).getOpenEnrollmentWindows(),
    );

/// ViewModel dedicada ao CADASTRO de competição (1:1 com CompetitionCreateScreen).
final competitionCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<CompetitionCreateViewModel>(
      (ref) => CompetitionCreateViewModel(
        repository: ref.watch(competitionRepositoryProvider),
      ),
    );

/// ViewModel dedicada à EDIÇÃO de competição (1:1 com CompetitionEditScreen).
final competitionEditViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<CompetitionEditViewModel, String>(
      (ref, id) => CompetitionEditViewModel(
        repository: ref.watch(competitionRepositoryProvider),
        competitionId: id,
      ),
    );

/// Serviço de inscrições de times (REST).
final competitionTeamServiceProvider = Provider<CompetitionTeamService>(
  (ref) => ApiCompetitionTeamService(ref.watch(apiClientProvider)),
);

/// Repositório de inscrições de times (Cache TTL 30s).
final competitionTeamRepositoryProvider = Provider<CompetitionTeamRepository>(
  (ref) => CompetitionTeamRepository(
    service: ref.watch(competitionTeamServiceProvider),
  ),
);

/// Parâmetro para o ViewModel de times de competição
class CompetitionTeamsParam {
  final String competitionId;
  final Competition? competition;

  const CompetitionTeamsParam({required this.competitionId, this.competition});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompetitionTeamsParam &&
          runtimeType == other.runtimeType &&
          competitionId == other.competitionId;

  @override
  int get hashCode => competitionId.hashCode;
}

/// ViewModel de equipes de uma competição.
final competitionTeamsViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<CompetitionTeamsViewModel, CompetitionTeamsParam>(
      (ref, param) => CompetitionTeamsViewModel(
        repository: ref.watch(competitionTeamRepositoryProvider),
        competitionId: param.competitionId,
        competition: param.competition,
      ),
    );

/// ViewModel de tabelamento de jogos da competição.
final competitionGamesViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<CompetitionGamesViewModel, CompetitionGamesParam>(
      (ref, param) => CompetitionGamesViewModel(
        gameRepo: ref.watch(gameRepositoryProvider),
        roundRepo: ref.watch(roundRepositoryProvider),
        teamRepo: ref.watch(competitionTeamRepositoryProvider),
        venueRepo: ref.watch(venueRepositoryProvider),
        client: ref.watch(apiClientProvider),
        competitionId: param.competitionId,
        competition: param.competition,
      ),
    );

/// Parâmetro para o ViewModel de jogos da competição
class CompetitionGamesParam {
  final String competitionId;
  final Competition? competition;

  const CompetitionGamesParam({required this.competitionId, this.competition});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompetitionGamesParam &&
          runtimeType == other.runtimeType &&
          competitionId == other.competitionId;

  @override
  int get hashCode => competitionId.hashCode;
}

/// Serviço de competições (REST API).
final competitionApiProvider = Provider<CompetitionApi>(
  (ref) => CompetitionApi(ref.watch(apiClientProvider)),
);

/// Serviço de times (REST API).
final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.watch(apiClientProvider)),
);

/// Serviço de conferências (REST API).
final conferenceApiProvider = Provider<ConferenceApi>(
  (ref) => ConferenceApi(ref.watch(apiClientProvider)),
);

/// Serviço de divisões (REST API).
final divisionApiProvider = Provider<DivisionApi>(
  (ref) => DivisionApi(ref.watch(apiClientProvider)),
);

/// Serviço de rodadas (REST API).
final roundApiProvider = Provider<RoundApi>(
  (ref) => RoundApi(ref.watch(apiClientProvider)),
);

/// Serviço de jogos (REST API).
final gameApiProvider = Provider<GameApi>(
  (ref) => GameApi(ref.watch(apiClientProvider)),
);

/// Lista de competições da tela de gestão.
final competitionsProvider = FutureProvider<List<Competition>>(
  (ref) => ref.watch(competitionApiProvider).listAll(),
);

/// Listagem para ADMIN: inclui desativados quando [includeDisabled].
final competitionsAdminProvider =
    FutureProvider.family<List<Competition>, bool>(
      (ref, includeDisabled) => ref
          .watch(competitionApiProvider)
          .listAll(includeDisabled: includeDisabled),
    );

/// Detalhe de uma competição por id.
final competitionProvider = FutureProvider.autoDispose
    .family<Competition, String>(
      (ref, id) => ref.watch(competitionApiProvider).getById(id),
    );

/// Competição selecionada na tela de competições.
final selectedCompetitionProvider = StateProvider<String?>((ref) => null);

/// Competência "efetiva" (P4 #461): a selecionada, ou a primeira da lista
/// quando nada foi escolhido — padrão `selected ?? first` duplicado em
/// várias telas (games, rounds, teams, rosters, associate_clubs, game_form).
final effectiveCompetitionProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedCompetitionProvider);
  if (selected != null) return selected;
  final comps = ref.watch(competitionsProvider).valueOrNull ?? const [];
  return comps.isNotEmpty ? comps.first.id : null;
});

/// Divisões de uma competição.
final divisionsProvider = FutureProvider.autoDispose
    .family<List<Division>, String>(
      (ref, competitionId) =>
          ref.watch(divisionApiProvider).listByCompetition(competitionId),
    );

/// Times de uma competição.
final teamsProvider = FutureProvider.autoDispose.family<List<Team>, String>(
  (ref, competitionId) =>
      ref.watch(teamApiProvider).listByCompetition(competitionId),
);

/// Detalhe de um time por id.
final teamProvider = FutureProvider.autoDispose.family<Team, String>(
  (ref, id) => ref.watch(teamApiProvider).getById(id),
);

/// Rodadas de uma competição.
final roundsProvider = FutureProvider.autoDispose.family<List<Round>, String>(
  (ref, competitionId) =>
      ref.watch(roundApiProvider).listByCompetition(competitionId),
);

/// Detalhe de uma rodada por id.
final roundProvider = FutureProvider.autoDispose.family<Round, String>(
  (ref, id) => ref.watch(roundApiProvider).getById(id),
);

/// Jogos de uma rodada.
final gamesByRoundProvider = FutureProvider.autoDispose
    .family<List<Game>, String>(
      (ref, roundId) => ref.watch(gameApiProvider).listByRound(roundId),
    );

/// Detalhe de um jogo por id.
final gameProvider = FutureProvider.autoDispose.family<Game, String>(
  (ref, id) => ref.watch(gameApiProvider).getById(id),
);
