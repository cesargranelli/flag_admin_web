import 'package:flag_admin_web/data/repositories/auth_controller.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/core/widgets/admin_shell.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/features/approvals/presentation/screens/approvals_screen.dart';
import 'package:flag_admin_web/src/features/competitions/presentation/screens/groupings_screen.dart';
import 'package:flag_admin_web/src/features/rosters/presentation/screens/rosters_screen.dart';
import 'package:flag_admin_web/src/features/users/presentation/screens/users_screen.dart';
import 'package:flag_admin_web/ui/auth/widgets/forgot_password_screen.dart';
import 'package:flag_admin_web/ui/auth/widgets/login_screen.dart';
import 'package:flag_admin_web/ui/auth/widgets/signup_screen.dart';
import 'package:flag_admin_web/ui/competition/widgets/competition_create_screen.dart';
import 'package:flag_admin_web/ui/competition/widgets/competition_detail_screen.dart';
import 'package:flag_admin_web/ui/competition/widgets/competition_edit_screen.dart';
import 'package:flag_admin_web/ui/competition/widgets/competition_games_screen.dart';
import 'package:flag_admin_web/ui/competition/widgets/competition_list_screen.dart';
import 'package:flag_admin_web/ui/competition/widgets/competition_teams_screen.dart';
import 'package:flag_admin_web/ui/game/widgets/game_create_screen.dart';
import 'package:flag_admin_web/ui/game/widgets/game_detail_screen.dart';
import 'package:flag_admin_web/ui/game/widgets/game_edit_screen.dart';
import 'package:flag_admin_web/ui/game/widgets/game_import_screen.dart';
import 'package:flag_admin_web/ui/game/widgets/game_list_screen.dart';
import 'package:flag_admin_web/ui/home/widgets/home_screen.dart';
import 'package:flag_admin_web/ui/institution/widgets/institution_create_screen.dart';
import 'package:flag_admin_web/ui/institution/widgets/institution_detail_screen.dart';
import 'package:flag_admin_web/ui/institution/widgets/institution_edit_screen.dart';
import 'package:flag_admin_web/ui/institution/widgets/institution_list_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_affiliates_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_create_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_detail_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_edit_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_list_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_create_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_detail_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_edit_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_import_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_list_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/roster_import_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/roster_screen.dart';
import 'package:flag_admin_web/ui/round/widgets/round_create_screen.dart';
import 'package:flag_admin_web/ui/round/widgets/round_detail_screen.dart';
import 'package:flag_admin_web/ui/round/widgets/round_edit_screen.dart';
import 'package:flag_admin_web/ui/round/widgets/round_list_screen.dart';
import 'package:flag_admin_web/ui/user/widgets/user_form_screen.dart';
import 'package:flag_admin_web/ui/venue/widgets/venue_create_screen.dart';
import 'package:flag_admin_web/ui/venue/widgets/venue_detail_screen.dart';
import 'package:flag_admin_web/ui/venue/widgets/venue_edit_screen.dart';
import 'package:flag_admin_web/ui/venue/widgets/venue_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Rotas do Admin Web com proteção de autenticação.
///
/// A navegação autenticada vive dentro de uma
/// [StatefulShellRoute.indexedStack] com uma branch por módulo (issue #427):
/// o [AdminShell] exibe header global + breadcrumb, e cada branch preserva
/// seu estado (filtros/seletores). Telas de autenticação ficam FORA da shell.
class AppRouter {
  /// Cria a configuração do GoRouter da aplicação.
  ///
  /// O [auth] é usado como `refreshListenable`: qualquer mudança de estado de
  /// autenticação reavalia o redirect (login/logout/proteção de rotas).
  static GoRouter build(AuthController auth) {
    // Destino original antes do redirect para o login (issue #429):
    // após autenticar, o usuário volta para onde tentava ir.
    String? pendingDestination;

    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final authState = auth.state;

        // Restaurando a sessão: mantém a tela de boot até decidir (#429).
        if (authState.restoring) return '/boot';

        final authenticated = authState.authenticated;
        final location = state.matchedLocation;
        final isPublicAuth =
            location == '/login' ||
            location == '/signup' ||
            location == '/forgot-password';
        final isBoot = location == '/boot';

        // Não autenticado: guarda o destino e vai para o login (#429).
        if (!authenticated) {
          if (!isPublicAuth && !isBoot) pendingDestination = location;
          return isPublicAuth ? null : '/login';
        }

        // Autenticado: sai das telas de autenticação e segue ao destino.
        if (isPublicAuth || isBoot) {
          final destination = pendingDestination;
          pendingDestination = null;
          return destination ?? '/';
        }
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.surfaceMuted, AppColors.background],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 56,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.notFoundTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline1.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.notFoundMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      KicksterButton(
                        label: AppStrings.backToHome,
                        variant: KicksterButtonVariant.outline,
                        onPressed: () => context.go('/'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      routes: [
        // ---------------------------------------------------------------- //
        // Telas públicas de autenticação (fora da shell).
        // ---------------------------------------------------------------- //
        GoRoute(
          path: '/boot',
          name: 'boot',
          builder: (context, state) => const _BootScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        // ---------------------------------------------------------------- //
        // Shell do site (header global: marca + usuário) com branches por
        // módulo. A navegação entre módulos é feita pelos cards da home.
        // ---------------------------------------------------------------- //
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AdminShell(navigationShell: navigationShell),
          branches: [
            // Branch Início.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  name: 'home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            // Branch Organizações.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/organizations',
                  name: 'organizations',
                  builder: (context, state) => const OrganizationListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'organizationNew',
                      builder: (context, state) =>
                          const OrganizationCreateScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      name: 'organizationDetail',
                      builder: (context, state) {
                        final org = state.extra is Organization
                            ? state.extra as Organization
                            : null;
                        return OrganizationDetailScreen(
                          organizationId: state.pathParameters['id'],
                          organization: org,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':id/edit',
                      name: 'organizationEdit',
                      builder: (context, state) {
                        final org = state.extra is Organization
                            ? state.extra as Organization
                            : null;
                        return OrganizationEditScreen(
                          id: state.pathParameters['id']!,
                          organization: org,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':id/affiliates',
                      name: 'organizationAffiliates',
                      builder: (context, state) {
                        final org = state.extra is Organization
                            ? state.extra as Organization
                            : null;
                        return OrganizationAffiliatesScreen(
                          organizationId: state.pathParameters['id']!,
                          organization: org,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Branch Competições (inclui conferências/divisões, rodadas e
            // jogos — acessados por contexto de competição).
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/competitions',
                  name: 'competitions',
                  builder: (context, state) => const CompetitionListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'competitionNew',
                      builder: (context, state) =>
                          const CompetitionCreateScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      name: 'competitionDetail',
                      builder: (context, state) {
                        final competition = state.extra is Competition
                            ? state.extra as Competition
                            : null;
                        return CompetitionDetailScreen(
                          id: state.pathParameters['id']!,
                          competition: competition,
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: 'competitionEdit',
                          builder: (context, state) {
                            final competition = state.extra is Competition
                                ? state.extra as Competition
                                : null;
                            return CompetitionEditScreen(
                              id: state.pathParameters['id']!,
                              competition: competition,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'teams',
                          name: 'competitionTeams',
                          builder: (context, state) {
                            final competition = state.extra is Competition
                                ? state.extra as Competition
                                : null;
                            return CompetitionTeamsScreen(
                              competitionId: state.pathParameters['id']!,
                              competition: competition,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'games',
                          name: 'competitionGames',
                          builder: (context, state) {
                            final competition = state.extra is Competition
                                ? state.extra as Competition
                                : null;
                            return CompetitionGamesScreen(
                              competitionId: state.pathParameters['id']!,
                              competition: competition,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: '/groupings',
                  name: 'groupings',
                  builder: (context, state) => const GroupingsScreen(),
                ),
                GoRoute(
                  path: '/rounds',
                  name: 'rounds',
                  builder: (context, state) => const RoundListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'roundNew',
                      builder: (context, state) => RoundCreateScreen(
                        competitionId: state.extra is String
                            ? state.extra as String
                            : null,
                      ),
                    ),
                    GoRoute(
                      path: ':id',
                      name: 'roundDetail',
                      builder: (context, state) {
                        final round = state.extra is Round
                            ? state.extra as Round
                            : null;
                        return RoundDetailScreen(
                          roundId: state.pathParameters['id'],
                          round: round,
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: 'roundEdit',
                          builder: (context, state) {
                            final round = state.extra is Round
                                ? state.extra as Round
                                : null;
                            return RoundEditScreen(
                              roundId: state.pathParameters['id']!,
                              round: round,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: '/games',
                  name: 'games',
                  builder: (context, state) => const GameListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'gameNew',
                      builder: (context, state) => GameCreateScreen(
                        args: state.extra is GameCreateArgs
                            ? state.extra as GameCreateArgs
                            : null,
                      ),
                    ),
                    GoRoute(
                      path: 'import',
                      name: 'gameImport',
                      builder: (context, state) {
                        final extra = state.extra;
                        final args = extra is GameImportArgs ? extra : null;
                        return GameImportScreen(
                          roundId:
                              args?.roundId ?? (extra is String ? extra : null),
                          competitionId: args?.competitionId,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':id',
                      name: 'gameDetail',
                      builder: (context, state) => GameDetailScreen(
                        gameId: state.pathParameters['id'],
                        game: state.extra is Game ? state.extra as Game : null,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: 'gameEdit',
                          builder: (context, state) => GameEditScreen(
                            gameId: state.pathParameters['id']!,
                            args: state.extra is GameEditArgs
                                ? state.extra as GameEditArgs
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Branch Campos (venues).
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/venues',
                  name: 'venues',
                  builder: (context, state) => const VenueListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'venueNew',
                      builder: (context, state) => const VenueCreateScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      name: 'venueDetail',
                      builder: (context, state) {
                        final venue = state.extra is Venue
                            ? state.extra as Venue
                            : null;
                        return VenueDetailScreen(
                          venueId: state.pathParameters['id'],
                          venue: venue,
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: 'venueEdit',
                          builder: (context, state) {
                            final venue = state.extra is Venue
                                ? state.extra as Venue
                                : null;
                            return VenueEditScreen(
                              venueId: state.pathParameters['id']!,
                              venue: venue,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Branch Pessoas.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/persons',
                  name: 'persons',
                  builder: (context, state) => const PersonListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'personNew',
                      builder: (context, state) => const PersonCreateScreen(),
                    ),
                    GoRoute(
                      path: 'import',
                      name: 'personImport',
                      builder: (context, state) => const PersonImportScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      name: 'personDetail',
                      builder: (context, state) {
                        final person = state.extra is Person
                            ? state.extra as Person
                            : null;
                        return PersonDetailScreen(
                          personId: state.pathParameters['id'],
                          person: person,
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: 'personEdit',
                          builder: (context, state) {
                            final person = state.extra is Person
                                ? state.extra as Person
                                : null;
                            return PersonEditScreen(
                              personId: state.pathParameters['id'],
                              person: person,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Branch Elencos.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/rosters',
                  name: 'rosters',
                  builder: (context, state) => const RostersScreen(),
                  routes: [
                    GoRoute(
                      path: 'import',
                      name: 'rosterImport',
                      builder: (context, state) => RosterImportScreen(
                        teamId: state.extra is String
                            ? state.extra as String
                            : null,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: '/teams/:id/roster',
                  name: 'teamRoster',
                  builder: (context, state) {
                    final team = state.extra is Team
                        ? state.extra as Team
                        : null;
                    return RosterScreen(
                      teamId: state.pathParameters['id'] ?? '',
                      team: team,
                    );
                  },
                ),
              ],
            ),
            // Branch Aprovações (somente ADMIN — protegida no backend).
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/approvals',
                  name: 'approvals',
                  builder: (context, state) => const ApprovalsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/institutions',
                  name: 'institutions',
                  builder: (context, state) => const InstitutionListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'institutionNew',
                      builder: (context, state) =>
                          const InstitutionCreateScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      name: 'institutionDetail',
                      builder: (context, state) {
                        final inst = state.extra is Institution
                            ? state.extra as Institution
                            : null;
                        return InstitutionDetailScreen(
                          id: state.pathParameters['id']!,
                          institution: inst,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':id/edit',
                      name: 'institutionEdit',
                      builder: (context, state) {
                        final inst = state.extra is Institution
                            ? state.extra as Institution
                            : null;
                        return InstitutionEditScreen(
                          id: state.pathParameters['id']!,
                          institution: inst,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Branch Usuários (somente ADMIN).
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/users',
                  name: 'users',
                  builder: (context, state) => const UsersScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: 'userNew',
                      builder: (context, state) => const UserFormScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Tela de boot exibida enquanto a sessão é restaurada (issue #429).
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoading(message: 'Restaurando sessão...'));
  }
}
