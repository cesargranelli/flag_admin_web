import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Tela para associar clubes/universidades ao campeonato selecionado.
///
/// Lista apenas as organizações que ainda NÃO possuem um [Team] no campeonato,
/// permitindo associar individualmente pelo ícone `group_add_outlined`.
/// Segue o mesmo padrão da tela de adicionar atleta ao elenco.
class RosterAssociateClubScreen extends ConsumerStatefulWidget {
  const RosterAssociateClubScreen({super.key, this.competitionId});

  /// Se informado, trava a tela neste campeonato. Caso contrário, usa o
  /// campeonato efetivo (selecionado ?? primeiro da lista).
  final String? competitionId;

  @override
  ConsumerState<RosterAssociateClubScreen> createState() =>
      _RosterAssociateClubScreenState();
}

class _RosterAssociateClubScreenState
    extends ConsumerState<RosterAssociateClubScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _associateScope = 'roster-associate-club';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitionId =
        widget.competitionId ?? ref.watch(effectiveCompetitionProvider);

    final breadcrumb = [
      const BreadcrumbItem('Início', route: '/'),
      const BreadcrumbItem('Elencos', route: '/rosters'),
      const BreadcrumbItem('Associar clube'),
    ];

    return AppScreen(
      title: 'Associar clube',
      scrollable: false,
      breadcrumb: breadcrumb,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLayout.content(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: KicksterSearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                hint: 'Buscar clube ou universidade',
              ),
            ),
          ),
          Expanded(
            child: competitionId != null
                ? _clubList(context, competitionId)
                : const AppEmptyState(
                    message: 'Nenhum campeonato selecionado',
                    icon: Icons.emoji_events_outlined,
                  ),
          ),
        ],
      ),
    );
  }

  /// Lista clubes/universidades que ainda não estão associados ao campeonato.
  Widget _clubList(BuildContext context, String competitionId) {
    final orgsAsync = ref.watch(organizationsProvider);
    final teamsAsync = ref.watch(teamsProvider(competitionId));

    if (orgsAsync.isLoading || teamsAsync.isLoading) {
      return const AppLoading(message: 'Carregando clubes...');
    }
    if (orgsAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar as organizações',
        onRetry: () => ref.invalidate(organizationsProvider),
      );
    }
    if (teamsAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar os times',
        onRetry: () => ref.invalidate(teamsProvider(competitionId)),
      );
    }

    final orgs = orgsAsync.value ?? const <Organization>[];
    final teams = teamsAsync.value ?? const <Team>[];

    // Mapa organização → time (para saber quem já está associado).
    final orgIdToTeam = <String, Team>{
      for (final team in teams)
        if (team.organizationId != null) team.organizationId!: team,
    };

    // Filtra: apenas clubes e universidades que ainda NÃO estão associados.
    final available = orgs.where((org) {
      final type = org.organizationType;
      if (type != null &&
          type != OrganizationType.club &&
          type != OrganizationType.university) {
        return false;
      }
      return !orgIdToTeam.containsKey(org.id);
    }).toList();

    if (available.isEmpty) {
      return const KicksterEmptyState(
        icon: Icons.groups_outlined,
        message: 'Todos os clubes já estão associados',
        description: 'Não há mais clubes disponíveis para associar.',
      );
    }

    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? available
        : available
            .where(
              (o) =>
                  o.tradeName.toLowerCase().contains(normalizedQuery) ||
                  (o.city ?? '').toLowerCase().contains(normalizedQuery),
            )
            .toList(growable: false);

    if (filtered.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhum clube encontrado',
        icon: Icons.search_off,
      );
    }

    return AppLayout.content(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 960
              ? 3
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 80,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final org = filtered[index];
              return _clubCard(context, org, competitionId);
            },
          );
        },
      ),
    );
  }

  /// Card de clube no estilo Kickster (mesmo padrão da lista de atletas):
  /// - Background: #ECF1F6 (Grayscale 20)
  /// - Border radius: 12px
  /// - Ícone do tipo à esquerda
  /// - Nome + subtítulo (cidade · tipo)
  /// - Ícone `group_add_outlined` para associar
  Widget _clubCard(
    BuildContext context,
    Organization org,
    String competitionId,
  ) {
    final subtitle = [
      if (org.city != null && org.city!.isNotEmpty) org.city!,
      if (org.organizationType != null) org.organizationType!.label,
    ].join(' · ');

    final associating =
        ref.watch(mutationProgressProvider(_associateScope)).contains(org.id);

    return Card(
      elevation: 0,
      color: AppColors.grayFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            // Ícone do tipo de organização (48x48 com border radius 12px)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                organizationTypeIcon(org.organizationType),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            // Nome + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.tradeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Ícone associar
            if (associating)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Associar ao campeonato',
                icon: const Icon(
                  Icons.link,
                  color: AppColors.primary,
                ),
                onPressed: () => _associate(org, competitionId),
              ),
          ],
        ),
      ),
    );
  }

  /// Associa o clube/universidade ao campeonato (cria o Team).
  Future<void> _associate(
    Organization org,
    String competitionId,
  ) async {
    await runMutation(
      context,
      ref: ref,
      scope: _associateScope,
      action: () => ref
          .read(teamApiProvider)
          .associateClub(
            competitionId: competitionId,
            organizationId: org.id,
          ),
      successMessage: '${org.tradeName} associado ao campeonato.',
      errorMessage: 'Não foi possível associar o clube.',
      progressId: org.id,
      onSuccess: () => ref.invalidate(teamsProvider(competitionId)),
    );
  }
}
