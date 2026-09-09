import 'package:flag_admin_web/src/api/api.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/data/repositories/auth_controller.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/data/services/auth_service.dart';
import 'package:flag_admin_web/ui/auth/view_models/forgot_password_view_model.dart';
import 'package:flag_admin_web/ui/auth/view_models/login_view_model.dart';
import 'package:flag_admin_web/ui/auth/view_models/signup_view_model.dart';
import 'package:flag_admin_web/ui/home/view_models/home_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/data/services/organization_service.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_detail_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_create_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_edit_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_affiliates_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/associate_clubs_view_model.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/data/services/institution_service.dart';
import 'package:flag_admin_web/data/services/storage_service.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_view_model.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_detail_view_model.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_create_view_model.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_edit_view_model.dart';

import 'package:flag_admin_web/data/repositories/competition_repository.dart';
import 'package:flag_admin_web/data/services/competition_service.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_list_view_model.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_detail_view_model.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_create_view_model.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_edit_view_model.dart';
import 'package:flag_admin_web/data/services/competition_team_service.dart';
import 'package:flag_admin_web/data/services/api_competition_team_service.dart';
import 'package:flag_admin_web/data/repositories/competition_team_repository.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_teams_view_model.dart';
import 'package:flag_admin_web/ui/team/view_models/team_roster_view_model.dart';
import 'package:flag_admin_web/data/services/round_service.dart';
import 'package:flag_admin_web/data/services/api_round_service.dart';
import 'package:flag_admin_web/data/repositories/round_repository.dart';
import 'package:flag_admin_web/data/services/game_service.dart';
import 'package:flag_admin_web/data/services/api_game_service.dart';
import 'package:flag_admin_web/data/repositories/game_repository.dart';
import 'package:flag_admin_web/data/services/venue_service.dart';
import 'package:flag_admin_web/data/services/api_venue_service.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_games_view_model.dart';

import '../router/app_router.dart';

/// Gerenciador de sessão do Admin Web (persiste dados de sessão Firebase/JWT).
final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

/// Cliente HTTP da API REST com o JWT do backend e Firebase ID Token injetados.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    sessionManager: ref.watch(sessionManagerProvider),
  ),
);

/// Serviço de autenticação Firebase e REST (ADR-001).
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiClientProvider)),
);

/// Repositório de autenticação (ADR-001 / Single Source of Truth).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    service: ref.watch(authServiceProvider),
    session: ref.watch(sessionManagerProvider),
  );
});

/// Instância do Firebase Storage.
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// Serviço de upload e armazenamento de mídia (Firebase Storage).
final storageServiceProvider = Provider<StorageService>((ref) {
  return FirebaseStorageService(ref.watch(firebaseStorageProvider));
});

/// Serviço de autenticação REST legado (compatibilidade com approvals_screen).
final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

/// Controlador de autenticação (restaura a sessão ao iniciar).
final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    repository: ref.watch(authRepositoryProvider),
  );
  controller.restore();
  return controller;
});

/// ViewModel para a tela de Login (ADR-001 / MVVM 1:1).
final loginViewModelProvider =
    ChangeNotifierProvider.autoDispose<LoginViewModel>((ref) {
  return LoginViewModel(
    repository: ref.watch(authRepositoryProvider),
    onAuthStateChanged: () =>
        ref.read(authControllerProvider).syncFromRepository(),
  );
});

/// ViewModel para a tela de Cadastro (ADR-001 / MVVM 1:1).
final signupViewModelProvider =
    ChangeNotifierProvider.autoDispose<SignupViewModel>((ref) {
  return SignupViewModel(
    repository: ref.watch(authRepositoryProvider),
  );
});

/// ViewModel para a tela de Esqueci a Senha (ADR-001 / MVVM 1:1).
final forgotPasswordViewModelProvider =
    ChangeNotifierProvider.autoDispose<ForgotPasswordViewModel>((ref) {
  return ForgotPasswordViewModel(
    repository: ref.watch(authRepositoryProvider),
  );
});

/// ViewModel para a tela Inicial / Home (ADR-001 / MVVM 1:1).
final homeViewModelProvider =
    ChangeNotifierProvider.autoDispose<HomeViewModel>((ref) {
  return HomeViewModel(
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Router com proteção de rotas.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  return AppRouter.build(auth);
});


/// Serviço de organizações (REST).
final organizationServiceProvider = Provider<OrganizationService>(
  (ref) => OrganizationService(ref.watch(apiClientProvider)),
);

/// Repository de organizações (Single Source of Truth, Caching).
final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => OrganizationRepository(
    service: ref.watch(organizationServiceProvider),
  ),
);

/// ViewModel de organizações (UI State e Commands).
final organizationViewModelProvider =
    ChangeNotifierProvider<OrganizationViewModel>(
  (ref) => OrganizationViewModel(
    repository: ref.watch(organizationRepositoryProvider),
  ),
);

/// ViewModel de detalhes de organização.
final organizationDetailViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<OrganizationDetailViewModel, String>(
  (ref, id) => OrganizationDetailViewModel(
    repository: ref.watch(organizationRepositoryProvider),
    organizationId: id,
  ),
);

/// Lista de janelas de filiação abertas no momento (para qualquer organização).
final openAffiliationWindowsProvider =
    FutureProvider.autoDispose<List<AffiliationWindow>>(
  (ref) => ref.watch(organizationRepositoryProvider).getOpenAffiliationWindows(),
);

/// ViewModel dedicada para a tela de Consulta de Agremiações Filiadas (ADR-001 / MVVM 1:1).
final organizationAffiliatesViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<OrganizationAffiliatesViewModel, String>(
  (ref, id) => OrganizationAffiliatesViewModel(
    repository: ref.watch(organizationRepositoryProvider),
    organizationId: id,
  ),
);



/// ViewModel dedicada para a tela de Criação de Organização (ADR-001 / MVVM 1:1).
final organizationCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<OrganizationCreateViewModel>(
  (ref) => OrganizationCreateViewModel(
    repository: ref.watch(organizationRepositoryProvider),
  ),
);

/// ViewModel dedicada para a tela de Edição de Organização (ADR-001 / MVVM 1:1).
final organizationEditViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<OrganizationEditViewModel, String>(
  (ref, id) => OrganizationEditViewModel(
    repository: ref.watch(organizationRepositoryProvider),
    organizationId: id,
  ),
);

/// ViewModel de associação de clubes.
final associateClubsViewModelProvider =
    ChangeNotifierProvider.autoDispose<AssociateClubsViewModel>(
  (ref) => AssociateClubsViewModel(),
);

/// Serviço de agremiações (REST).
final institutionServiceProvider = Provider<InstitutionService>(
  (ref) => ApiInstitutionService(ref.watch(apiClientProvider)),
);

/// Repository de agremiações (Single Source of Truth, Caching).
final institutionRepositoryProvider = Provider<InstitutionRepository>(
  (ref) => InstitutionRepository(
    service: ref.watch(institutionServiceProvider),
  ),
);

/// ViewModel de agremiações (UI State e Commands).
final institutionViewModelProvider =
    ChangeNotifierProvider<InstitutionViewModel>(
  (ref) => InstitutionViewModel(
    repository: ref.watch(institutionRepositoryProvider),
  ),
);

/// ViewModel de detalhes de agremiação.
final institutionDetailViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<InstitutionDetailViewModel, String>(
  (ref, id) => InstitutionDetailViewModel(
    repository: ref.watch(institutionRepositoryProvider),
    institutionId: id,
  ),
);

/// ViewModel dedicada ao CADASTRO de agremiação (1:1 com InstitutionCreateScreen).
final institutionCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<InstitutionCreateViewModel>(
  (ref) => InstitutionCreateViewModel(
    repository: ref.watch(institutionRepositoryProvider),
  ),
);

/// ViewModel dedicada à EDIÇÃO de agremiação (1:1 com InstitutionEditScreen).
final institutionEditViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<InstitutionEditViewModel, String>(
  (ref, id) => InstitutionEditViewModel(
    repository: ref.watch(institutionRepositoryProvider),
    institutionId: id,
  ),
);

/// Serviço de competições (REST).
final competitionServiceProvider = Provider<CompetitionService>(
  (ref) => ApiCompetitionService(ref.watch(apiClientProvider)),
);

/// Repository de competições (Single Source of Truth, Caching).
final competitionRepositoryProvider = Provider<CompetitionRepository>(
  (ref) => CompetitionRepository(
    service: ref.watch(competitionServiceProvider),
  ),
);

/// ViewModel de listagem de competições.
final competitionListViewModelProvider =
    ChangeNotifierProvider<CompetitionListViewModel>(
  (ref) => CompetitionListViewModel(
    repository: ref.watch(competitionRepositoryProvider),
  ),
);

/// ViewModel de detalhes de competição (1:1 com CompetitionDetailScreen).
final competitionDetailViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<CompetitionDetailViewModel, String>(
  (ref, id) => CompetitionDetailViewModel(
    repository: ref.watch(competitionRepositoryProvider),
    competitionId: id,
  ),
);

/// ViewModel dedicada ao CADASTRO de competição (1:1 com CompetitionCreateScreen).
final competitionCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<CompetitionCreateViewModel>(
  (ref) => CompetitionCreateViewModel(
    repository: ref.watch(competitionRepositoryProvider),
  ),
);

/// ViewModel dedicada à EDIÇÃO de competição (1:1 com CompetitionEditScreen).
final competitionEditViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<CompetitionEditViewModel, String>(
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

  const CompetitionTeamsParam({
    required this.competitionId,
    this.competition,
  });

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

/// Serviço de rodadas (REST).
final roundServiceProvider = Provider<RoundService>(
  (ref) => ApiRoundService(ref.watch(apiClientProvider)),
);

/// Repositório de rodadas (Cache TTL 30s).
final roundRepositoryProvider = Provider<RoundRepository>(
  (ref) => RoundRepository(
    service: ref.watch(roundServiceProvider),
  ),
);

/// Serviço de jogos (REST).
final gameServiceProvider = Provider<GameService>(
  (ref) => ApiGameService(ref.watch(apiClientProvider)),
);

/// Repositório de jogos (Cache TTL 30s).
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => GameRepository(
    service: ref.watch(gameServiceProvider),
  ),
);

/// Serviço de praças esportivas / venues (REST).
final venueServiceProvider = Provider<VenueService>(
  (ref) => ApiVenueService(ref.watch(apiClientProvider)),
);

/// Repositório de praças esportivas (Cache TTL 60s).
final venueRepositoryProvider = Provider<VenueRepository>(
  (ref) => VenueRepository(
    service: ref.watch(venueServiceProvider),
  ),
);

/// Parâmetro para o ViewModel de jogos da competição
class CompetitionGamesParam {
  final String competitionId;
  final Competition? competition;

  const CompetitionGamesParam({
    required this.competitionId,
    this.competition,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompetitionGamesParam &&
          runtimeType == other.runtimeType &&
          competitionId == other.competitionId;

  @override
  int get hashCode => competitionId.hashCode;
}

/// ViewModel de jogos/tabelamento de uma competição.
final competitionGamesViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<CompetitionGamesViewModel, CompetitionGamesParam>(
  (ref, param) => CompetitionGamesViewModel(
    gameRepo: ref.watch(gameRepositoryProvider),
    roundRepo: ref.watch(roundRepositoryProvider),
    teamRepo: ref.watch(competitionTeamRepositoryProvider),
    venueRepo: ref.watch(venueRepositoryProvider),
    competitionId: param.competitionId,
    competition: param.competition,
  ),
);



/// Listagem de organizações da tela de gestão.
///
/// Listagem via Repository, expondo apenas organizações ATIVAS.
/// Recarrega via `ref.invalidate(organizationsProvider)` após mutações.
final organizationsProvider = FutureProvider<List<Organization>>(
  (ref) => ref.watch(organizationRepositoryProvider).getOrganizations(),
);

/// Listagem para ADMIN: inclui desativadas quando [includeDisabled].
final organizationsAdminProvider =
    FutureProvider.family<List<Organization>, bool>(
  (ref, includeDisabled) => ref
      .watch(organizationRepositoryProvider)
      .getOrganizations(includeDisabled: includeDisabled),
);

/// Detalhe de uma organização por id.
final organizationProvider =
    FutureProvider.autoDispose.family<Organization, String>(
  (ref, id) =>
      ref.watch(organizationRepositoryProvider).getOrganization(id),
);

/// Serviço de competições.
final competitionApiProvider = Provider<CompetitionApi>(
  (ref) => CompetitionApi(ref.watch(apiClientProvider)),
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
final competitionProvider = FutureProvider.autoDispose.family<Competition, String>(
  (ref, id) => ref.watch(competitionApiProvider).getById(id),
);

/// Competição selecionada na tela de competições.
final selectedCompetitionProvider = StateProvider<String?>((ref) => null);

/// Competição "efetiva" (P4 #461): a selecionada, ou a primeira da lista
/// quando nada foi escolhido — padrão `selected ?? first` duplicado em
/// várias telas (games, rounds, teams, rosters, associate_clubs, game_form).
final effectiveCompetitionProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedCompetitionProvider);
  if (selected != null) return selected;
  final comps = ref.watch(competitionsProvider).valueOrNull ?? const [];
  return comps.isNotEmpty ? comps.first.id : null;
});

/// Serviço de times.
final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.watch(apiClientProvider)),
);

/// Serviço de conferências.
final conferenceApiProvider = Provider<ConferenceApi>(
  (ref) => ConferenceApi(ref.watch(apiClientProvider)),
);

/// Serviço de divisões.
final divisionApiProvider = Provider<DivisionApi>(
  (ref) => DivisionApi(ref.watch(apiClientProvider)),
);

/// Conferências de uma competição.
final conferencesProvider = FutureProvider.autoDispose.family<List<Conference>, String>(
  (ref, competitionId) =>
      ref.watch(conferenceApiProvider).listByCompetition(competitionId),
);

/// Divisões de uma competição.
final divisionsProvider = FutureProvider.autoDispose.family<List<Division>, String>(
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

/// Serviço de rodadas.
final roundApiProvider = Provider<RoundApi>(
  (ref) => RoundApi(ref.watch(apiClientProvider)),
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

/// Serviço de jogos.
final gameApiProvider = Provider<GameApi>(
  (ref) => GameApi(ref.watch(apiClientProvider)),
);

/// Rodada selecionada na tela de jogos.
final selectedRoundProvider = StateProvider<String?>((ref) => null);

/// Jogos de uma rodada.
final gamesByRoundProvider = FutureProvider.autoDispose.family<List<Game>, String>(
  (ref, roundId) => ref.watch(gameApiProvider).listByRound(roundId),
);

/// Detalhe de um jogo por id.
final gameProvider = FutureProvider.autoDispose.family<Game, String>(
  (ref, id) => ref.watch(gameApiProvider).getById(id),
);

/// Serviço de atletas.
final athleteApiProvider = Provider<AthleteApi>(
  (ref) => AthleteApi(ref.watch(apiClientProvider)),
);

/// Lista de atletas.
final athletesProvider = FutureProvider<List<Athlete>>(
  (ref) => ref.watch(athleteApiProvider).list(),
);

/// Detalhe de um atleta por id.
final athleteProvider = FutureProvider.autoDispose.family<Athlete, String>(
  (ref, id) => ref.watch(athleteApiProvider).getById(id),
);

/// Serviço de elencos.
final rosterApiProvider = Provider<RosterApi>(
  (ref) => RosterApi(ref.watch(apiClientProvider)),
);

/// Time selecionado na tela de elencos.
final selectedTeamProvider = StateProvider<String?>((ref) => null);

/// Elenco de um time.
final rosterProvider = FutureProvider.autoDispose.family<List<RosterEntry>, String>(
  (ref, teamId) => ref.watch(rosterApiProvider).listByTeam(teamId),
);

/// ViewModel da tela de Gestao de Elenco (ADR-001 / MVVM).
///
/// Usa family por teamId para que cada time tenha sua propria instancia.
final teamRosterViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<TeamRosterViewModel, String>(
  (ref, teamId) => TeamRosterViewModel(
    rosterApi: ref.read(rosterApiProvider),
    teamId: teamId,
  ),
);

/// Lista de usuários (somente ADMIN).
final usersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(authApiProvider).listUsers(),
);

/// Contas pendentes de aprovação (somente ADMIN).
final pendingUsersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(authApiProvider).listPendingUsers(),
);

/// Serviço de campos de jogo.
final venueApiProvider = Provider<VenueApi>(
  (ref) => VenueApi(ref.watch(apiClientProvider)),
);

/// Listagem de campos de jogo da tela de gestão.
///
/// Listagem via REST (`GET /api/v1/venues`), sem filtro de status (não
/// existe ACTIVE para venue — lista TODOS). Recarrega via
/// `ref.invalidate(venuesProvider)` após mutações.
final venuesProvider = FutureProvider<List<Venue>>(
  (ref) => ref.watch(venueApiProvider).list(),
);

/// Detalhe de um campo por id.
///
/// Permanece via REST (leitura pontual, não realtime) — consumidores
/// secundários (venue_detail) não mudam na #53.
final venueProvider = FutureProvider.autoDispose.family<Venue, String>(
  (ref, id) => ref.watch(venueApiProvider).getById(id),
);
/// Listagem de agremiações da tela de gestão.
final institutionsProvider = FutureProvider<List<Institution>>(
  (ref) => ref.watch(institutionRepositoryProvider).getInstitutions(),
);

/// Listagem para ADMIN: inclui desativadas quando [includeDisabled].
final institutionsAdminProvider =
    FutureProvider.family<List<Institution>, bool>(
  (ref, includeDisabled) => ref
      .watch(institutionRepositoryProvider)
      .getInstitutions(forceRefresh: false),
);

/// Detalhe de uma agremiação por id.
final institutionProvider =
    FutureProvider.autoDispose.family<Institution, String>(
  (ref, id) =>
      ref.watch(institutionRepositoryProvider).getInstitution(id),
);


