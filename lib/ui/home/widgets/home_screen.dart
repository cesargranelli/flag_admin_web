import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';

/// Tela inicial do Admin Web — estrutura visual Kickster (ADR-001 / MVVM).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin =
        ref.watch(authControllerProvider.select((a) => a.state.user?.role)) ==
        UserRole.admin;

    final modules = <_Module>[
      const _Module(
        Icons.business_outlined,
        AppStrings.organizations,
        '/organizations',
      ),
      const _Module(
        Icons.shield_outlined,
        AppStrings.institutions,
        '/institutions',
      ),
      const _Module(
        Icons.emoji_events_outlined,
        AppStrings.competitions,
        '/competitions',
      ),
      const _Module(
        Icons.groups_outlined,
        AppStrings.rosters,
        '/rosters',
      ),
      const _Module(
        Icons.person_outline,
        AppStrings.athletes,
        '/athletes',
      ),
      const _Module(
        Icons.stadium_outlined,
        AppStrings.venues,
        '/venues',
      ),
      if (isAdmin)
        const _Module(
          Icons.fact_check_outlined,
          AppStrings.approvals,
          '/approvals',
        ),
      if (isAdmin)
        const _Module(
          Icons.manage_accounts_outlined,
          AppStrings.users,
          '/users',
        ),
    ];

    return AppScreen(
      title: AppStrings.home,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: AppStrings.modules),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: wide ? 1.6 : 1.3,
                children: [
                  for (final module in modules)
                    KicksterCard(
                      icon: module.icon,
                      title: module.title,
                      onTap: () => context.go(module.route),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _Module {
  final IconData icon;
  final String title;
  final String route;

  const _Module(this.icon, this.title, this.route);
}
