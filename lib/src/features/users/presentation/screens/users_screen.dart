import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/providers.dart';

/// Gestão de usuários (somente ADMIN): lista e acesso ao formulário.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);

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
            child: users.when(
              loading: () =>
                  const AppLoading(message: 'Carregando usuários...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os usuários',
                onRetry: () => ref.invalidate(usersProvider),
              ),
              data: (items) {
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
      UserRole.mesa => AppColors.success,
      UserRole.organizer => AppColors.primary,
    };
    return KicksterBadge(label: label, color: color);
  }
}
