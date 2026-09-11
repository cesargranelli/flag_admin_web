import 'package:flag_admin_web/data/repositories/auth_controller.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/core/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'branches/admin_branches.dart';
import 'branches/auth_routes.dart';
import 'branches/competition_branch.dart';
import 'branches/home_branch.dart';
import 'branches/organization_branch.dart';
import 'branches/person_branch.dart';
import 'branches/roster_branch.dart';
import 'branches/venue_branch.dart';

class AppRouter {
  static GoRouter build(AuthController auth) {
    String? pendingDestination;
    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final authState = auth.state;
        if (authState.restoring) return '/boot';
        final authenticated = authState.authenticated;
        final location = state.matchedLocation;
        final isPublicAuth = location == '/login' || location == '/signup' || location == '/forgot-password';
        final isBoot = location == '/boot';
        if (!authenticated) {
          if (!isPublicAuth && !isBoot) pendingDestination = location;
          return isPublicAuth ? null : '/login';
        }
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
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.surfaceMuted, AppColors.background]),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_off, size: 56, color: AppColors.danger),
                    const SizedBox(height: 16),
                    Text(AppStrings.notFoundTitle, textAlign: TextAlign.center, style: AppTextStyles.headline1.copyWith(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(AppStrings.notFoundMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 24),
                    KicksterButton(label: AppStrings.backToHome, variant: KicksterButtonVariant.outline, onPressed: () => context.go('/')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      routes: [
        ...authRoutes,
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AdminShell(navigationShell: navigationShell),
          branches: [
            homeBranch,
            organizationBranch,
            competitionBranch,
            venueBranch,
            personBranch,
            rosterBranch,
            approvalsBranch,
            institutionBranch,
            usersBranch,
          ],
        ),
      ],
    );
  }
}
