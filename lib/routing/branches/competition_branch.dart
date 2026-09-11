import 'package:flag_admin_web/src/domain/domain.dart';
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
import 'package:flag_admin_web/ui/round/widgets/round_create_screen.dart';
import 'package:flag_admin_web/ui/round/widgets/round_detail_screen.dart';
import 'package:flag_admin_web/ui/round/widgets/round_edit_screen.dart';
import 'package:flag_admin_web/ui/round/widgets/round_list_screen.dart';
import 'package:go_router/go_router.dart';

final competitionBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/competitions',
      name: 'competitions',
      builder: (c, s) => const CompetitionListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'competitionNew',
          builder: (c, s) => const CompetitionCreateScreen(),
        ),
        GoRoute(
          path: ':id',
          name: 'competitionDetail',
          builder: (c, s) {
            final competition = s.extra is Competition
                ? s.extra as Competition
                : null;
            return CompetitionDetailScreen(
              id: s.pathParameters['id']!,
              competition: competition,
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'competitionEdit',
              builder: (c, s) {
                final competition = s.extra is Competition
                    ? s.extra as Competition
                    : null;
                return CompetitionEditScreen(
                  id: s.pathParameters['id']!,
                  competition: competition,
                );
              },
            ),
            GoRoute(
              path: 'teams',
              name: 'competitionTeams',
              builder: (c, s) {
                final competition = s.extra is Competition
                    ? s.extra as Competition
                    : null;
                return CompetitionTeamsScreen(
                  competitionId: s.pathParameters['id']!,
                  competition: competition,
                );
              },
            ),
            GoRoute(
              path: 'games',
              name: 'competitionGames',
              builder: (c, s) {
                final competition = s.extra is Competition
                    ? s.extra as Competition
                    : null;
                return CompetitionGamesScreen(
                  competitionId: s.pathParameters['id']!,
                  competition: competition,
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/rounds',
      name: 'rounds',
      builder: (c, s) => const RoundListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'roundNew',
          builder: (c, s) => RoundCreateScreen(
            competitionId: s.extra is String ? s.extra as String : null,
          ),
        ),
        GoRoute(
          path: ':id',
          name: 'roundDetail',
          builder: (c, s) {
            final round = s.extra is Round ? s.extra as Round : null;
            return RoundDetailScreen(
              roundId: s.pathParameters['id'],
              round: round,
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'roundEdit',
              builder: (c, s) {
                final round = s.extra is Round ? s.extra as Round : null;
                return RoundEditScreen(
                  roundId: s.pathParameters['id']!,
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
      builder: (c, s) => const GameListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'gameNew',
          builder: (c, s) => GameCreateScreen(
            args: s.extra is GameCreateArgs ? s.extra as GameCreateArgs : null,
          ),
        ),
        GoRoute(
          path: 'import',
          name: 'gameImport',
          builder: (c, s) {
            final extra = s.extra;
            final args = extra is GameImportArgs ? extra : null;
            return GameImportScreen(
              roundId: args?.roundId ?? (extra is String ? extra : null),
              competitionId: args?.competitionId,
            );
          },
        ),
        GoRoute(
          path: ':id',
          name: 'gameDetail',
          builder: (c, s) => GameDetailScreen(
            gameId: s.pathParameters['id'],
            game: s.extra is Game ? s.extra as Game : null,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              name: 'gameEdit',
              builder: (c, s) => GameEditScreen(
                gameId: s.pathParameters['id']!,
                args: s.extra is GameEditArgs ? s.extra as GameEditArgs : null,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
