import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/ui/approval/widgets/approval_list_screen.dart';
import 'package:flag_admin_web/ui/institution/widgets/institution_create_screen.dart';
import 'package:flag_admin_web/ui/institution/widgets/institution_detail_screen.dart';
import 'package:flag_admin_web/ui/institution/widgets/institution_edit_screen.dart';
import 'package:flag_admin_web/ui/institution/widgets/institution_list_screen.dart';
import 'package:flag_admin_web/ui/user/widgets/user_form_screen.dart';
import 'package:flag_admin_web/ui/user/widgets/user_list_screen.dart';
import 'package:go_router/go_router.dart';

final approvalsBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/approvals',
      name: 'approvals',
      builder: (c, s) => const ApprovalListScreen(),
    ),
  ],
);

final institutionBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/institutions',
      name: 'institutions',
      builder: (c, s) => const InstitutionListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'institutionNew',
          builder: (c, s) => const InstitutionCreateScreen(),
        ),
        GoRoute(
          path: ':id',
          name: 'institutionDetail',
          builder: (c, s) {
            final inst = s.extra is Institution ? s.extra as Institution : null;
            return InstitutionDetailScreen(
              id: s.pathParameters['id']!,
              institution: inst,
            );
          },
        ),
        GoRoute(
          path: ':id/edit',
          name: 'institutionEdit',
          builder: (c, s) {
            final inst = s.extra is Institution ? s.extra as Institution : null;
            return InstitutionEditScreen(
              id: s.pathParameters['id']!,
              institution: inst,
            );
          },
        ),
      ],
    ),
  ],
);

final usersBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/users',
      name: 'users',
      builder: (c, s) => const UserListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'userNew',
          builder: (c, s) => const UserFormScreen(),
        ),
      ],
    ),
  ],
);
