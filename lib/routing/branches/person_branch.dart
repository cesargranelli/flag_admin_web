import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/ui/person/widgets/person_create_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_detail_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_edit_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_import_screen.dart';
import 'package:flag_admin_web/ui/person/widgets/person_list_screen.dart';
import 'package:go_router/go_router.dart';

final personBranch = StatefulShellBranch(routes: [
  GoRoute(
    path: '/persons',
    name: 'persons',
    builder: (c, s) => const PersonListScreen(),
    routes: [
      GoRoute(path: 'new', name: 'personNew', builder: (c, s) => const PersonCreateScreen()),
      GoRoute(path: 'import', name: 'personImport', builder: (c, s) => const PersonImportScreen()),
      GoRoute(
        path: ':id',
        name: 'personDetail',
        builder: (c, s) {
          final person = s.extra is Person ? s.extra as Person : null;
          return PersonDetailScreen(personId: s.pathParameters['id'], person: person);
        },
        routes: [
          GoRoute(path: 'edit', name: 'personEdit', builder: (c, s) {
            final person = s.extra is Person ? s.extra as Person : null;
            return PersonEditScreen(personId: s.pathParameters['id'], person: person);
          }),
        ],
      ),
    ],
  ),
]);
