import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_affiliates_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_create_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_detail_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_edit_screen.dart';
import 'package:flag_admin_web/ui/organization/widgets/organization_list_screen.dart';
import 'package:go_router/go_router.dart';

final organizationBranch = StatefulShellBranch(routes: [
  GoRoute(
    path: '/organizations',
    name: 'organizations',
    builder: (c, s) => const OrganizationListScreen(),
    routes: [
      GoRoute(path: 'new', name: 'organizationNew', builder: (c, s) => const OrganizationCreateScreen()),
      GoRoute(
        path: ':id',
        name: 'organizationDetail',
        builder: (c, s) {
          final org = s.extra is Organization ? s.extra as Organization : null;
          return OrganizationDetailScreen(organizationId: s.pathParameters['id'], organization: org);
        },
      ),
      GoRoute(
        path: ':id/edit',
        name: 'organizationEdit',
        builder: (c, s) {
          final org = s.extra is Organization ? s.extra as Organization : null;
          return OrganizationEditScreen(id: s.pathParameters['id']!, organization: org);
        },
      ),
      GoRoute(
        path: ':id/affiliates',
        name: 'organizationAffiliates',
        builder: (c, s) {
          final org = s.extra is Organization ? s.extra as Organization : null;
          return OrganizationAffiliatesScreen(organizationId: s.pathParameters['id']!, organization: org);
        },
      ),
    ],
  ),
]);
