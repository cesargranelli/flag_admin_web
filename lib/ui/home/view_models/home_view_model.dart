import 'package:flutter/material.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';

/// Item de módulo navegável na tela inicial.
class HomeModuleItem {
  final IconData icon;
  final String title;
  final String route;

  const HomeModuleItem({
    required this.icon,
    required this.title,
    required this.route,
  });
}

/// ViewModel para a tela inicial / Dashboard (ADR-001 / MVVM 1:1).
class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  HomeViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  UserRole? get userRole => _authRepository.currentUser?.role;
  bool get isAdmin => userRole == UserRole.admin;

  /// Retorna os módulos do sistema acessíveis ao usuário atual.
  List<HomeModuleItem> get modules {
    return [
      const HomeModuleItem(
        icon: Icons.business_outlined,
        title: AppStrings.organizations,
        route: '/organizations',
      ),
      const HomeModuleItem(
        icon: Icons.shield_outlined,
        title: AppStrings.institutions,
        route: '/institutions',
      ),
      const HomeModuleItem(
        icon: Icons.emoji_events_outlined,
        title: AppStrings.competitions,
        route: '/competitions',
      ),
      const HomeModuleItem(
        icon: Icons.groups_outlined,
        title: AppStrings.rosters,
        route: '/rosters',
      ),
      const HomeModuleItem(
        icon: Icons.person_outline,
        title: AppStrings.athletes,
        route: '/athletes',
      ),
      const HomeModuleItem(
        icon: Icons.stadium_outlined,
        title: AppStrings.venues,
        route: '/venues',
      ),
      if (isAdmin)
        const HomeModuleItem(
          icon: Icons.fact_check_outlined,
          title: AppStrings.approvals,
          route: '/approvals',
        ),
      if (isAdmin)
        const HomeModuleItem(
          icon: Icons.manage_accounts_outlined,
          title: AppStrings.users,
          route: '/users',
        ),
    ];
  }
}
