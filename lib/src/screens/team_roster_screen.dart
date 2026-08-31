import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Elenco de um time (clube) num campeonato (issue #360/#363/#8).
///
/// A tela mostra **apenas os atletas que já estão no elenco** (roster).
/// Para adicionar mais atletas, há um botão que leva para a tela de seleção
/// ([RosterAddAthleteScreen]). A remoção de atletas é feita diretamente
/// nesta tela.
///
/// Requer [rosterId] para acessar as entradas do elenco.
class TeamRosterScreen extends ConsumerStatefulWidget {
  const TeamRosterScreen({
    super.key,
    this.team,
    this.teamId,
    required this.rosterId,
  });

  /// Time (clube + competição) quando navegamos com `state.extra`.
  final Team? team;

  /// Id do time, derivado da rota `/teams/:id/roster`.
  final String? teamId;

  /// ID do elenco (roster) para buscar as entradas.
  final String rosterId;

  @override
  ConsumerState<TeamRosterScreen> createState() => _TeamRosterScreenState();
}

class _TeamRosterScreenState extends ConsumerState<TeamRosterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const _removeScope = 'roster-remove';

  String? get _teamId => widget.team?.id ?? widget.teamId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _removeAthlete(RosterEntry entry) async {
    final rosterId = widget.rosterId;

    await runMutation(
      context,
      ref: ref,
      scope: _removeScope,
      action: () => ref
          .read(rosterApiProvider)
          .remove(rosterId, entry.athleteId),
      successMessage: '${entry.athleteName} removido do elenco.',
      errorMessage: 'Não foi possível remover o atleta.',
      progressId: entry.athleteId,
      onSuccess: () => ref.invalidate(rosterEntriesProvider(rosterId)),
    );
  }

  void _navigateToAddAthlete() {
    final teamId = _teamId;
    final teamName = widget.team?.name ?? 'Elenco';
    if (teamId == null) return;
    context.push(
      '/teams/$teamId/roster/add',
      extra: (teamId: teamId, teamName: teamName, rosterId: widget.rosterId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamId = _teamId;
    final teamFuture = widget.team != null
        ? null
        : teamId != null
        ? ref.watch(teamProvider(teamId))
        : null;
    final teamName = widget.team?.name ?? teamFuture?.valueOrNull?.name;
    final title = teamName ?? 'Elenco';

    final breadcrumb = [
      const BreadcrumbItem('Início', route: '/'),
      const BreadcrumbItem(AppStrings.teams, route: '/teams'),
      if (teamName != null && teamId != null)
        BreadcrumbItem(teamName, route: '/teams/$teamId'),
      const BreadcrumbItem('Elenco'),
    ];

    return AppScreen(
      title: title,
      scrollable: false,
      breadcrumb: breadcrumb,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de ações: busca + botões
          AppLayout.content(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: KicksterSearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      hint: 'Buscar atleta no elenco',
                    ),
                  ),
                  const SizedBox(width: 12),
                  KicksterButton(
                    label: 'Adicionar atleta',
                    icon: Icons.person_add_outlined,
                    onPressed: _navigateToAddAthlete,
                  ),
                  const SizedBox(width: 8),
                  if (teamId != null)
                    IconButton(
                      tooltip: 'Importar CSV',
                      icon: const Icon(Icons.upload_file),
                      onPressed: () => context.push(
                        '/rosters/import',
                        extra: (teamId: teamId, rosterId: widget.rosterId),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Conteúdo (Expanded para dar altura finita à lista lazy)
          Expanded(
            child: teamId == null
                ? const AppEmptyState(
                    message: 'Time não identificado',
                    icon: Icons.groups_outlined,
                  )
                : _buildRoster(context, widget.rosterId),
          ),
        ],
      ),
    );
  }

  Widget _buildRoster(BuildContext context, String rosterId) {
    final rosterAsync = ref.watch(rosterEntriesProvider(rosterId));
    final athletesAsync = ref.watch(athletesProvider);

    if (rosterAsync.isLoading || athletesAsync.isLoading) {
      return const AppLoading(message: 'Carregando elenco...');
    }
    if (rosterAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar o elenco',
        onRetry: () => ref.invalidate(rosterEntriesProvider(rosterId)),
      );
    }
    if (athletesAsync.hasError) {
      return AppErrorState(
        message: 'Não foi possível carregar os atletas',
        onRetry: () => ref.invalidate(athletesProvider),
      );
    }

    final entries = rosterAsync.value ?? const <RosterEntry>[];
    final athletes = athletesAsync.value ?? const <Athlete>[];

    // Mapa de atletas por ID para lookup rápido
    final athleteById = {for (final a in athletes) a.id: a};

    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? entries
        : entries
            .where(
              (e) =>
                  e.athleteName.toLowerCase().contains(normalizedQuery),
            )
            .toList(growable: false);

    return _buildList(
      entries: filtered,
      athleteById: athleteById,
      isEmpty: entries.isEmpty,
    );
  }

  Widget _buildList({
    required List<RosterEntry> entries,
    required Map<String, Athlete> athleteById,
    required bool isEmpty,
  }) {
    if (isEmpty) {
      return KicksterEmptyState(
        icon: Icons.person_outline,
        message: 'Nenhum atleta no elenco',
        description: 'Adicione atletas ao elenco deste time.',
        action: KicksterButton(
          label: 'Adicionar atleta',
          icon: Icons.person_add_outlined,
          onPressed: _navigateToAddAthlete,
        ),
      );
    }
    if (entries.isEmpty) {
      return const AppEmptyState(
        message: 'Nenhum atleta encontrado',
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
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final athlete = athleteById[entry.athleteId];
              return _athleteCard(context, entry, athlete);
            },
          );
        },
      ),
    );
  }

  /// Card de atleta no estilo Figma (node 34442:3299):
  /// - Background: #ECF1F6 (Grayscale 20)
  /// - Border radius: 12px
  /// - Padding: 4px 10px
  /// - Avatar: 60x60, border radius 16px
  /// - Nome: 14px Medium #111111
  /// - Subtítulo: 12px Regular #9CA4AB
  /// - Valor à direita: 14px SemiBold #000000
  Widget _athleteCard(
    BuildContext context,
    RosterEntry entry,
    Athlete? athlete,
  ) {
    // Dados do atleta (fallback para dados do entry se não encontrado)
    final name = athlete?.name ?? entry.athleteName;
    final photoUrl = athlete?.photoUrl;
    final position = athlete?.positionsLabel ?? '';

    // Apelido e número do elenco (prioridade) ou do atleta
    final displayNickname = entry.nickname ?? entry.athleteNickname;
    final displayNumber = entry.number ?? athlete?.number;

    final subtitle = [
      if (displayNumber != null) '#$displayNumber',
      if (displayNickname != null && displayNickname.isNotEmpty)
        displayNickname,
      if (position.isNotEmpty) position,
    ].join(' · ');

    final removing =
        ref.watch(mutationProgressProvider(_removeScope)).contains(entry.athleteId);

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
            // Avatar 60x60 com border radius 16px
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 60,
                height: 60,
                child: KicksterAvatar(
                  name: name,
                  imageUrl: photoUrl,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nome + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
            // Botão remover
            if (removing)
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
                tooltip: 'Remover do elenco',
                icon: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.danger,
                ),
                onPressed: () => _removeAthlete(entry),
              ),
          ],
        ),
      ),
    );
  }
}
