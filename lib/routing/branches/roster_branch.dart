import 'package:flag_admin_web/config/domain_imports.dart';
import 'package:flag_admin_web/ui/person/widgets/roster_import_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/roster_screen.dart';
import 'package:go_router/go_router.dart';

final rosterBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/rosters',
      name: 'rosters',
      builder: (c, s) => const RosterScreen(),
      routes: [
        GoRoute(
          path: 'import',
          name: 'rosterImport',
          builder: (c, s) => RosterImportScreen(
            teamId: s.extra is String ? s.extra as String : null,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/teams/:id/roster',
      name: 'teamRoster',
      builder: (c, s) {
        final team = s.extra is Team ? s.extra as Team : null;
        return RosterScreen(teamId: s.pathParameters['id'] ?? '', team: team);
      },
    ),
  ],
);
