import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../utils/date_formats.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Detalhe de um campeonato em página única (#455): todas as seções
/// (campeonato, modalidade, categoria, temporada, conferências, agrupamento,
/// clubes) empilhadas com títulos de seção — o scroll é do body, sem barras
/// internas.
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  const CompetitionDetailScreen({
    super.key,
    this.competitionId,
    this.competition,
  });

  final String? competitionId;
  final Competition? competition;

  @override
  ConsumerState<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final compFuture = widget.competition != null
        ? null
        : ref.watch(competitionProvider(widget.competitionId!));

    return AppScreen(
      title: widget.competition?.name ?? 'Campeonato',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          compFuture == null
              ? _buildDetail(context, widget.competition!)
              : compFuture.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando campeonato...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar o campeonato',
                    onRetry: () => ref.invalidate(
                      competitionProvider(widget.competitionId!),
                    ),
                  ),
                  data: (comp) => _buildDetail(context, comp),
                ),
        ],
      ),
    );
  }

  /// Página única: seções empilhadas, scroll do body (#455).
  Widget _buildDetail(BuildContext context, Competition comp) {
    // Issue #261: edição exige ser criador do campeonato ou ADMIN.
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      comp,
    );
    final isDraft = comp.status == CompetitionStatus.draft;

    return AppLayout.detail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section(
              title: 'Campeonato',
              icon: Icons.emoji_events_outlined,
              child: _campeonatoCard(context, comp, canEdit, isDraft),
            ),
            _section(
              title: 'Modalidade',
              icon: Icons.sports_football_outlined,
              child: _modalidadeCard(comp),
            ),
            _section(
              title: 'Categoria',
              icon: Icons.groups_outlined,
              child: _categoriaCard(comp),
            ),
            _section(
              title: 'Temporada',
              icon: Icons.date_range,
              child: _temporadaCard(comp),
            ),
            _section(
              title: 'Conferências',
              icon: Icons.account_tree_outlined,
              child: _conferencesCard(comp),
            ),
            _section(
              title: 'Agrupamento',
              icon: Icons.hub_outlined,
              child: _estruturaCard(context, comp, canEdit, isDraft),
            ),
            _section(
              title: 'Times',
              icon: Icons.groups,
              child: _teamsCard(context, comp, canEdit, isDraft),
            ),
          ],
        ),
    );
  }

  /// Título de seção (titleMedium) + card, separados por espaçamento padrão.
  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(title: title, icon: icon),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  /// Seção 1 — Campeonato (#306): identidade + ações por status,
  /// espelhando a primeira seção do formulário de cadastro.
  Widget _campeonatoCard(
    BuildContext context,
    Competition comp,
    bool canEdit,
    bool isDraft,
  ) {
    // Resolve o nome da organização a partir do provider.
    final orgs = ref.watch(organizationsProvider).valueOrNull ??
        const <Organization>[];
    final orgName = comp.organizationId != null
        ? orgs
            .where((o) => o.id == comp.organizationId)
            .map((o) => o.tradeName)
            .firstOrNull
        : null;
    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comp.organizationName ??
                            (orgName ?? 'Organização'),
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _statusChip(comp.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // V250: edição permitida apenas enquanto rascunho.
            // Issue #261: e apenas pelo criador ou ADMIN.
            // Status lifecycle: publicado pode ser encerrado (PUBLISHED →
            // FINISHED) por quem pode editar.
            if (isDraft && canEdit)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  KicksterButton(
                    label: 'Editar campeonato',
                    icon: Icons.edit_outlined,
                    onPressed: () => context.go(
                      '/competitions/${comp.id}/edit',
                      extra: comp,
                    ),
                  ),
                  // Issue #381: novo ponto de entrada para rodadas/confrontos,
                  // ao lado de "Editar campeonato" (recupera o acesso a /rounds).
                  KicksterButton(
                    label: 'Rodadas',
                    icon: Icons.format_list_numbered,
                    variant: KicksterButtonVariant.outline,
                    onPressed: () {
                      ref.read(selectedCompetitionProvider.notifier).state =
                          comp.id;
                      context.go('/rounds');
                    },
                  ),
                ],
              )
            else if (canEdit && comp.status == CompetitionStatus.published)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  KicksterButton(
                    label: 'Encerrar campeonato',
                    icon: Icons.flag,
                    variant: KicksterButtonVariant.outline,
                    onPressed: () => _finishCompetition(context, comp),
                  ),
                ],
              )
            else
              Text(
                isDraft
                    ? 'Apenas o criador do campeonato pode editá-lo.'
                    : comp.status == CompetitionStatus.finished
                        ? 'Campeonato encerrado — não é mais editável.'
                        : 'Campeonato publicado — não é mais editável.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            // Descrição pertence à seção Campeonato (formulário).
            if (comp.description != null && comp.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppInfoRow(label: 'Descrição', value: comp.description!),
            ],
          ],
        ),
      ),
    );
  }

  /// Seção 2 — Modalidade (#306).
  Widget _modalidadeCard(Competition comp) {
    return AppInfoCard(
      children: [
        AppInfoRow(
          label: 'Modalidade',
          value: comp.modality?.label ?? 'Não definido',
        ),
      ],
    );
  }

  /// Seção 3 — Categoria (#306): gênero + faixa etária.
  Widget _categoriaCard(Competition comp) {
    return AppInfoCard(
      children: [
        AppInfoRow(label: 'Gênero', value: _genderLabel(comp.gender)),
        AppInfoRow(label: 'Faixa etária', value: _ageGroupLabel(comp.ageGroup)),
      ],
    );
  }

  /// Seção 4 — Temporada (#306).
  Widget _temporadaCard(Competition comp) {
    return AppInfoCard(
      children: [
        if (comp.startDate != null)
          AppInfoRow(label: 'Início', value: formatBrDate(comp.startDate!)),
        if (comp.endDate != null)
          AppInfoRow(label: 'Fim', value: formatBrDate(comp.endDate!)),
        if (comp.startDate == null && comp.endDate == null)
          AppInfoRow(label: 'Período', value: 'Não definido'),
      ],
    );
  }

  /// Seção 6 — Agrupamento (#306/#349): reflete apenas o que foi cadastrado
  /// (divisões/grupos), sem a linha "Modelo" nem botões de ação.
  Widget _estruturaCard(
    BuildContext context,
    Competition comp,
    bool canEdit,
    bool isDraft,
  ) {
    final divisions = ref.watch(divisionsProvider(comp.id));
    final conferences =
        ref.watch(conferencesProvider(comp.id)).valueOrNull ??
        const <Conference>[];
    return divisions.when(
      loading: () => const AppLoading(
        message: 'Carregando agrupamento...',
      ),
      error: (e, s) => AppErrorState(
        message: 'Não foi possível carregar as divisões.',
        onRetry: () => ref.invalidate(divisionsProvider(comp.id)),
      ),
      data: (items) => AppInfoCard(
        children: items.isEmpty
            ? const [
                Text(
                  'Nenhuma divisão ou grupo adicionado.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ]
            : [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final division in items)
                      _divisionChip(
                        division.name,
                        conferenceName: division.conferenceId == null
                            ? null
                            : conferences
                                  .where((c) => c.id == division.conferenceId)
                                  .map((c) => c.name)
                                  .firstOrNull,
                      ),
                  ],
                ),
              ],
      ),
    );
  }

  /// Seção 7 — Times (#12): lista dos times inscritos no campeonato +
  /// botão para a tela de inscrição. O time é a unidade inscrita (não a
  /// organização), então não há mais resolução `Team.organizationId` → `Organization`.
  Widget _teamsCard(
    BuildContext context,
    Competition comp,
    bool canEdit,
    bool isDraft,
  ) {
    final teams = ref.watch(teamsProvider(comp.id));

    return teams.when(
      loading: () => const AppLoading(
        message: 'Carregando times...',
      ),
      error: (e, s) => AppErrorState(
        message: 'Não foi possível carregar os times.',
        onRetry: () => ref.invalidate(teamsProvider(comp.id)),
      ),
      data: (items) => AppInfoCard(
        children: [
          if (items.isEmpty)
            const Text(
              'Nenhum time inscrito.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final team in items)
                  _teamChip(
                    team.name,
                    subtitle:
                        team.shortName?.isNotEmpty == true
                        ? team.shortName
                        : null,
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (canEdit && isDraft)
            KicksterButton(
              label: 'Inscrever times',
              icon: Icons.add,
              onPressed: () {
                ref.read(selectedCompetitionProvider.notifier).state =
                    comp.id;
                context.push('/teams/associate', extra: comp.id);
              },
            )
          else
            const Text(
              'Apenas o criador do campeonato pode inscrever times.',
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _teamChip(String name, {String? subtitle}) {
    final label = subtitle == null ? name : '$name · $subtitle';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seção Conferências (#323/#345): lista as conferências do campeonato.
  Widget _conferencesCard(Competition comp) {
    final conferences = ref.watch(conferencesProvider(comp.id));
    return conferences.when(
      loading: () => const AppLoading(
        message: 'Carregando conferências...',
      ),
      error: (e, s) => AppErrorState(
        message: 'Não foi possível carregar as conferências.',
        onRetry: () => ref.invalidate(conferencesProvider(comp.id)),
      ),
      data: (items) => AppInfoCard(
        children: items.isEmpty
            ? const [
                Text(
                  'Nenhuma conferência adicionada.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ]
            : [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final c in items) _conferenceChip(c.name)],
                ),
              ],
      ),
    );
  }

  Widget _conferenceChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _divisionChip(String name, {String? conferenceName}) {
    final label = conferenceName == null ? name : '$name · $conferenceName';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(CompetitionStatus status) {
    final color = switch (status) {
      CompetitionStatus.draft => AppColors.textSecondary,
      CompetitionStatus.published => AppColors.success,
      CompetitionStatus.finished => AppColors.danger,
      CompetitionStatus.disabled => AppColors.textSecondary,
    };
    return KicksterBadge(label: _statusLabel(status), color: color);
  }

  /// Encerra um campeonato publicado (PUBLISHED → FINISHED).
  ///
  /// Ação irreversível: pede confirmação em modo danger e, após a mutação,
  /// invalida a listagem e o detalhe para refletir o novo status.
  Future<void> _finishCompetition(
    BuildContext context,
    Competition comp,
  ) async {
    final ok = await showKicksterConfirm(
      context: context,
      title: 'Encerrar campeonato',
      content: 'O campeonato não poderá mais ser editado após encerrado.',
      confirmLabel: 'Encerrar',
      danger: true,
    );
    if (ok != true || !context.mounted) return;
    await runMutation(
      context,
      ref: ref,
      scope: 'competition-finish',
      action: () => ref.read(competitionApiProvider).finish(comp.id),
      successMessage: 'Campeonato encerrado.',
      errorMessage: 'Não foi possível encerrar o campeonato.',
      progressId: comp.id,
      onSuccess: () {
        ref.invalidate(competitionsProvider);
        ref.invalidate(competitionProvider(comp.id));
      },
    );
  }

  String _statusLabel(CompetitionStatus status) => switch (status) {
    CompetitionStatus.draft => 'Rascunho',
    CompetitionStatus.published => 'Publicado',
    CompetitionStatus.finished => 'Encerrado',
    CompetitionStatus.disabled => 'Desativado',
  };

  // M12 #473: usa os labels do DOMAIN (Gender/AgeGroup.fromJson) em vez de
  // switches sobre strings — sem drift quando o domain mudar. Fallback
  // 'Não definido' para valores desconhecidos/nulos.
  String _genderLabel(String? gender) {
    if (gender == null) return 'Não definido';
    try {
      return Gender.fromJson(gender).label;
    } on FormatException {
      return 'Não definido';
    }
  }

  String _ageGroupLabel(String? ageGroup) {
    if (ageGroup == null) return 'Não definido';
    try {
      return AgeGroup.fromJson(ageGroup).label;
    } on FormatException {
      return 'Não definido';
    }
  }
}