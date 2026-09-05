import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/domain/competition_permissions.dart';
import '../../../../providers/providers.dart';

/// Gestão de competições: cards de acesso e navegação para o detalhe.
///
/// Listagem em grid de cards (padrão web); clicar navega para a tela de
/// detalhe da competição. ADMIN pode exibir desativados e gerenciá-los.
class CompetitionsScreen extends ConsumerStatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  ConsumerState<CompetitionsScreen> createState() =>
      _CompetitionsScreenState();
}

class _CompetitionsScreenState extends ConsumerState<CompetitionsScreen> {
  bool _showDisabled = false;
  final _searchController = TextEditingController();

  static const _scope = 'competitions';

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
    final user = ref.watch(authControllerProvider.select((a) => a.state.user));
    final showDisabled = isAdmin && _showDisabled;
    final competitions = showDisabled
        ? ref.watch(competitionsAdminProvider(true))
        : ref.watch(competitionsProvider);

    return AppScreen(
      title: AppStrings.competitions,
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.competitions),
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
                onPressed: () => context.go('/competitions/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: competitions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando competições...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar as competições',
                onRetry: () => showDisabled
                    ? ref.invalidate(competitionsAdminProvider(true))
                    : ref.invalidate(competitionsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.emoji_events_outlined,
                    message: 'Nenhuma competição cadastrada',
                    description:
                        'Crie a primeira competição para começar a usar.',
                    action: KicksterButton(
                      label: 'Criar competição',
                      icon: Icons.add,
                      onPressed: () => context.go('/competitions/new'),
                    ),
                  );
                }
                return AppEntityListScreen<Competition>(
                  items: items,
                  cardBuilder: (competition) =>
                      _competitionCard(context, competition, user),
                  searchField: _searchController,
                  countLabel: 'competições',
                  emptyMessage: 'Nenhuma competição encontrada',
                  toolbarTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAdmin)
                        Tooltip(
                          message: 'Exibir competições desativadas',
                          child: IconButton(
                            isSelected: _showDisabled,
                            selectedIcon: const Icon(Icons.visibility),
                            icon: const Icon(Icons.visibility_off_outlined),
                            tooltip: 'Desativados',
                            onPressed: () =>
                                setState(() => _showDisabled = !_showDisabled),
                          ),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where((c) => c.name.toLowerCase().contains(query))
                          .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Card de competição no padrão Kickster (core #439): ícone do troféu,
  /// nome (+ organização como subtítulo) e menu de gestão para quem pode
  /// editar (#261). Badges de modalidade/gênero/faixa e status continuam
  /// visíveis no detalhe.
  Widget _competitionCard(BuildContext context, Competition competition, dynamic user) {
    final isDisabled = competition.status == CompetitionStatus.disabled;
    return KicksterCard(
      icon: Icons.emoji_events_outlined,
      title: competition.name,
      subtitle:
          (competition.organizationName?.isNotEmpty ?? false)
              ? competition.organizationName
              : null,
      onTap: () =>
          context.push('/competitions/${competition.id}', extra: competition),
      // Issue #261: ações de gestão (desativar/reativar) exigem
      // ser criador da competição ou ADMIN — o backend já bloqueia.
      trailing: canEditCompetition(
        user,
        competition,
      )
          ? PopupMenuButton<String>(
              tooltip: 'Ações',
              onSelected: (value) async {
                if (value == 'deactivate') {
                  final ok = await _confirm(
                    context,
                    'Desativar competição',
                    '"${competition.name}" ficará invisível para os '
                        'demais usuários até ser reativado.',
                  );
                  if (ok == true) await _deactivate(competition);
                } else if (value == 'reactivate') {
                  await _reactivate(competition);
                }
              },
              itemBuilder: (_) => [
                if (!isDisabled)
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Text('Desativar'),
                  ),
                if (isDisabled)
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reativar'),
                  ),
              ],
            )
          : null,
    );
  }

  Future<bool?> _confirm(BuildContext context, String title, String message) {
    return showKicksterConfirm(
      context: context,
      title: title,
      content: message,
      confirmLabel: 'Desativar',
      danger: true,
    );
  }

  void _invalidateLists() {
    ref.invalidate(competitionsProvider);
    ref.invalidate(competitionsAdminProvider(true));
  }

  Future<void> _deactivate(Competition competition) => _toggleActive(
        competition,
        activate: false,
        successMessage: '${competition.name} desativado.',
        errorMessage: 'Não foi possível desativar a competição.',
      );

  Future<void> _reactivate(Competition competition) => _toggleActive(
        competition,
        activate: true,
        successMessage: '${competition.name} reativado.',
        errorMessage: 'Não foi possível reativar a competição.',
      );

  Future<void> _toggleActive(
    Competition competition, {
    required bool activate,
    required String successMessage,
    required String errorMessage,
  }) async {
    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () => activate
          ? ref.read(competitionApiProvider).reactivate(competition.id)
          : ref.read(competitionApiProvider).deactivate(competition.id),
      successMessage: successMessage,
      errorMessage: errorMessage,
      progressId: competition.id,
      onSuccess: _invalidateLists,
    );
  }
}
