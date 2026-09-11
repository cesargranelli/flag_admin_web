import 'package:flag_admin_web/ui/home/widgets/home_screen.dart';
import 'package:go_router/go_router.dart';

final homeBranch = StatefulShellBranch(routes: [
  GoRoute(path: '/', name: 'home', builder: (c, s) => const HomeScreen()),
]);
