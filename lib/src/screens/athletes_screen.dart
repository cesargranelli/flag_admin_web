import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

/// Gestão de atletas: cards e navegação para o detalhe.
class AthletesScreen extends ConsumerStatefulWidget {
  const AthletesScreen({super.key});

  @override
  ConsumerState<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends ConsumerState<AthletesScreen> {
  static const _scope = 'athletes';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        ref.watch(authControllerProvider.select((a) => a.state.user?.role)) ==
        UserRole.admin;
    final athletes = ref.watch(athletesProvider);

    return AppScreen(
      title: 'Atletas',
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Importar',
                icon: Icons.upload_file,
                variant: KicksterButtonVariant.outline,
                onPressed: () => context.push('/athletes/import'),
              ),
              const SizedBox(width: 8),
              KicksterButton(
                label: 'Novo',
                icon: Icons.add,
                onPressed: () => context.push('/athletes/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: athletes.when(
              loading: () => const AppLoading(message: 'Carregando atletas...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os atletas',
                onRetry: () => ref.invalidate(athletesProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.person_outline,
                    message: 'Nenhum atleta cadastrado',
                    description: 'Crie o primeiro atleta para começar a usar.',
                    action: KicksterButton(
                      label: 'Criar atleta',
                      icon: Icons.add,
                      onPressed: () => context.push('/athletes/new'),
                    ),
                  );
                }
                return AppEntityListScreen<Athlete>(
                  items: items,
                  cardBuilder: (athlete) =>
                      _athleteCard(context, athlete, isAdmin),
                  searchField: _searchController,
                  countLabel: 'atletas',
                  countLabelSingular: 'atleta',
                  emptyMessage: 'Nenhum atleta encontrado',
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where(
                              (a) => a.name.toLowerCase().contains(query))
                          .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Card de atleta no padrão Kickster (core #439): ícone de pessoa, nome e
  /// subtítulo com número + posições. Para ADMIN, mostra badge de inativo e
  /// menu de desativar/reativar (status lifecycle).
  Widget _athleteCard(BuildContext context, Athlete athlete, bool isAdmin) {
    final positions = athlete.positionsLabel;
    final subtitle = [
      if (athlete.number != null) '#${athlete.number}',
      if (positions.isNotEmpty) positions,
    ].join(' · ');
    final isInactive = athlete.status == 'INACTIVE';

    return KicksterCard(
      icon: Icons.person_outline,
      title: athlete.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      onTap: () => context.push('/athletes/${athlete.id}', extra: athlete),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isInactive) _inactiveBadge(),
          if (isAdmin)
            PopupMenuButton<String>(
              tooltip: 'Ações',
              onSelected: (value) async {
                if (value == 'deactivate') {
                  final ok = await _confirmDeactivate(context, athlete);
                  if (ok == true) await _deactivate(athlete);
                } else if (value == 'reactivate') {
                  await _reactivate(athlete);
                }
              },
              itemBuilder: (_) => [
                if (!isInactive)
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Text('Desativar'),
                  ),
                if (isInactive)
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reativar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _inactiveBadge() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: KicksterBadge(label: 'Inativo', color: AppColors.danger),
    );
  }

  Future<bool?> _confirmDeactivate(BuildContext context, Athlete athlete) {
    return showKicksterConfirm(
      context: context,
      title: 'Desativar atleta',
      content: '"${athlete.name}" ficará inativo até ser reativado.',
      confirmLabel: 'Desativar',
      danger: true,
    );
  }

  Future<void> _deactivate(Athlete athlete) => _toggleActive(
        athlete,
        activate: false,
        successMessage: '${athlete.name} desativado.',
        errorMessage: 'Não foi possível desativar o atleta.',
      );

  Future<void> _reactivate(Athlete athlete) => _toggleActive(
        athlete,
        activate: true,
        successMessage: '${athlete.name} reativado.',
        errorMessage: 'Não foi possível reativar o atleta.',
      );

  Future<void> _toggleActive(
    Athlete athlete, {
    required bool activate,
    required String successMessage,
    required String errorMessage,
  }) async {
    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () => activate
          ? ref.read(athleteApiProvider).reactivate(athlete.id)
          : ref.read(athleteApiProvider).deactivate(athlete.id),
      successMessage: successMessage,
      errorMessage: errorMessage,
      progressId: athlete.id,
      onSuccess: () => ref.invalidate(athletesProvider),
    );
  }
}
