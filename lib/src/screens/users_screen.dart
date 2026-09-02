import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

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
      title: 'Usuários',
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
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
                  return const KicksterEmptyState(
                    icon: Icons.people_outline,
                    message: 'Nenhum usuário cadastrado',
                    description:
                        'Os usuários se cadastram pelo formulário de cadastro público.',
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

  /// Card de usuário no padrão Kickster: ícone genérico de pessoa, nome,
  /// e-mail como subtítulo e chip do papel à direita. Não há rota de detalhe
  /// de usuário no app — o toque é um no-op (sem navegação).
  Widget _userCard(BuildContext context, User user) {
    return KicksterCard(
      icon: Icons.person_outline,
      title: user.name,
      subtitle: user.email,
      trailing: _roleChip(user.role, user.role.label),
      onTap: () {},
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
