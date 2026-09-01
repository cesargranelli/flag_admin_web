import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_entity_list_screen.dart';
import '../widgets/app_screen.dart';

/// Módulo Times da home: lista TODOS os times cadastrados na plataforma.
///
/// Este canal é apenas de **visualização**: o cadastro de times acontece no
/// detalhe do clube (`/organizations/:id` → seção "Times" → "Novo time"), e a
/// inscrição em campeonatos na tela dedicada. Por isso não há botão de
/// criar/inscrever aqui.
class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  static const _scope = 'teams';
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
    final teamsAsync = ref.watch(allTeamsProvider);
    // Nome do clube por id (via organizações) para enriquecer o subtítulo.
    final orgs = ref.watch(organizationsProvider).valueOrNull ?? const [];
    final orgNames = {for (final o in orgs) o.id: o.tradeName};

    return AppScreen(
      title: 'Times',
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: teamsAsync.when(
              loading: () =>
                  const AppLoading(message: 'Carregando times...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os times',
                onRetry: () => ref.invalidate(allTeamsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.groups_outlined,
                    message: 'Nenhum time cadastrado',
                    description:
                        'Crie o primeiro time no detalhe de um clube.',
                  );
                }
                return AppEntityListScreen<Team>(
                  items: items,
                  cardBuilder: (team) =>
                      _teamCard(context, team, orgNames, isAdmin),
                  searchField: _searchController,
                  countLabel: 'times',
                  countLabelSingular: 'time',
                  emptyMessage: 'Nenhum time encontrado',
                  filter: (all, query) => query.isEmpty
                      ? all
                      : all
                          .where(
                            (t) =>
                                t.name.toLowerCase().contains(query) ||
                                (t.shortName?.toLowerCase().contains(query) ??
                                    false),
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

  /// Card de time no padrão Kickster: ícone de grupos, nome (16 w600),
  /// subtítulo com sigla · esporte + clube quando resolvido. Para ADMIN,
  /// mostra badge de inativo e menu de desativar/reativar (status
  /// lifecycle). Tocar navega para o detalhe do time.
  Widget _teamCard(
    BuildContext context,
    Team team,
    Map<String, String> orgNames,
    bool isAdmin,
  ) {
    final subtitleParts = [
      if (team.shortName?.isNotEmpty ?? false) team.shortName!,
      if (team.sportName?.isNotEmpty ?? false) team.sportName!,
    ].join(' · ');
    final orgName = orgNames[team.organizationId];
    final isInactive = team.status == 'INACTIVE';

    // Subtítulo em linha única (limite do KicksterCard): sigla · esporte
    // combinados com o nome do clube quando resolvido.
    final subtitle = [
      if (subtitleParts.isNotEmpty) subtitleParts,
      ?orgName,
    ].join(' · ');

    return KicksterCard(
      icon: Icons.groups_outlined,
      title: team.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      onTap: () => context.push('/teams/${team.id}', extra: team),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isInactive) ...[
            KicksterBadge(label: 'Inativo', color: AppColors.danger),
            const SizedBox(width: 8),
          ],
          if (isAdmin)
            PopupMenuButton<String>(
              tooltip: 'Ações',
              onSelected: (value) async {
                if (value == 'deactivate') {
                  final ok = await _confirmDeactivate(context, team);
                  if (ok == true) await _deactivate(team);
                } else if (value == 'reactivate') {
                  await _reactivate(team);
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
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            size: 22,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeactivate(BuildContext context, Team team) {
    return showKicksterConfirm(
      context: context,
      title: 'Desativar time',
      content: '"${team.name}" ficará inativo até ser reativado.',
      confirmLabel: 'Desativar',
      danger: true,
    );
  }

  Future<void> _deactivate(Team team) => _toggleActive(
        team,
        activate: false,
        successMessage: '${team.name} desativado.',
        errorMessage: 'Não foi possível desativar o time.',
      );

  Future<void> _reactivate(Team team) => _toggleActive(
        team,
        activate: true,
        successMessage: '${team.name} reativado.',
        errorMessage: 'Não foi possível reativar o time.',
      );

  Future<void> _toggleActive(
    Team team, {
    required bool activate,
    required String successMessage,
    required String errorMessage,
  }) async {
    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () => activate
          ? ref.read(teamApiProvider).reactivate(team.id)
          : ref.read(teamApiProvider).deactivate(team.id),
      successMessage: successMessage,
      errorMessage: errorMessage,
      progressId: team.id,
      onSuccess: () => ref.invalidate(allTeamsProvider),
    );
  }
}
