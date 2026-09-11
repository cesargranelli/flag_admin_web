import 'package:flag_admin_web/config/domain_imports.dart';
import 'package:flag_admin_web/ui/venue/widgets/venue_create_screen.dart';
import 'package:flag_admin_web/ui/venue/widgets/venue_detail_screen.dart';
import 'package:flag_admin_web/ui/venue/widgets/venue_edit_screen.dart';
import 'package:flag_admin_web/ui/venue/widgets/venue_list_screen.dart';
import 'package:go_router/go_router.dart';

final venueBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/venues',
      name: 'venues',
      builder: (c, s) => const VenueListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'venueNew',
          builder: (c, s) => const VenueCreateScreen(),
        ),
        GoRoute(
          path: ':id',
          name: 'venueDetail',
          builder: (c, s) {
            final venue = s.extra is Venue ? s.extra as Venue : null;
            return VenueDetailScreen(
              venueId: s.pathParameters['id'],
              venue: venue,
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'venueEdit',
              builder: (c, s) {
                final venue = s.extra is Venue ? s.extra as Venue : null;
                return VenueEditScreen(
                  venueId: s.pathParameters['id']!,
                  venue: venue,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
