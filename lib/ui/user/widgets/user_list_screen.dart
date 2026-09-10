import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/user/view_models/user_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Gestão de usuários (somente ADMIN): lista e acesso ao formulário.
class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _searchController = TextEditingController();
  late UserListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(userListViewModelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.load(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: AppStrings.users,
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.users),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Novo',
                icon: Icons.add,
                onPressed: () => context.go('/users/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading) {
                  return const AppLoading(message: 'Carregando usuários...');
                }

                if (_viewModel.errorMessage != null) {
                  return AppErrorState(
                    message: _viewModel.errorMessage!,
                    onRetry: () => _viewModel.load(forceRefresh: true),
                  );
                }

                final items = _viewModel.filteredUsers;
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.people_outline,
                    message: 'Nenhum usuário cadastrado',
                    description:
                        'Crie o primeiro usuário para começar a usar.',
                    action: KicksterButton(
                      label: 'Criar usuário',
                      icon: Icons.add,
                      onPressed: () => context.go('/users/new'),
                    ),
                  );
                }
                return AppEntityListScreen<User>(
                  items: items,
                  cardBuilder: (user) => _userCard(context, user),
                  searchField: _searchController,
                  countLabel: 'usuários',
                  countLabelSingular: 'usuário',
                  emptyMessage: 'Nenhum usuário encontrado',
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where(
                            (u) =>
                                u.name.toLowerCase().contains(query) ||
                                u.email.toLowerCase().contains(query),
                          )
                          .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, User user) {
    final role = user.role.label;
    return KicksterCard(
      icon: Icons.person_outline,
      title: user.name,
      subtitle: user.email,
      onTap: () {},
      trailing: _roleChip(user.role, role),
    );
  }

  Widget _roleChip(UserRole role, String label) {
    final color = switch (role) {
      UserRole.admin => AppColors.danger,
      UserRole.adminLiga => AppColors.danger,
      UserRole.mesa => AppColors.success,
      UserRole.organizer => AppColors.primary,
      UserRole.manager => AppColors.primary,
      UserRole.referee => AppColors.warning,
      UserRole.clubManager => AppColors.primary,
      UserRole.fan => AppColors.textSecondary,
    };
    return KicksterBadge(label: label, color: color);
  }
}