import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/domain/competition_permissions.dart';
import 'package:flag_admin_web/ui/round/view_models/round_detail_view_model.dart'
    as vm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detalhe de uma rodada: apresenta os dados e oferece a edição.
class RoundDetailScreen extends ConsumerStatefulWidget {
  const RoundDetailScreen({super.key, this.roundId, this.round});

  final String? roundId;
  final Round? round;

  @override
  ConsumerState<RoundDetailScreen> createState() => _RoundDetailScreenState();
}

class _RoundDetailScreenState extends ConsumerState<RoundDetailScreen> {
  late vm.RoundDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = vm.RoundDetailViewModel(
      repository: ref.watch(roundRepositoryProvider),
    );
    if (widget.roundId != null) {
      _viewModel.load(widget.roundId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: widget.round?.name ?? 'Rodada',
      breadcrumb: [
        const BreadcrumbItem(AppStrings.home, route: '/'),
        const BreadcrumbItem(AppStrings.rounds, route: '/rounds'),
        if (widget.round?.name != null) BreadcrumbItem(widget.round!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading) {
                return const AppLoading(message: 'Carregando rodada...');
              }

              if (_viewModel.errorMessage != null) {
                return AppErrorState(
                  message: _viewModel.errorMessage!,
                  onRetry: () => _viewModel.load(widget.roundId!),
                );
              }

              final round = _viewModel.round;
              if (round == null) {
                return const AppErrorState(message: 'Rodada não encontrada');
              }

              return _buildDetail(context, round);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Round round) {
    final compAsync = ref.watch(competitionProvider(round.competitionId));
    final competitionName = compAsync.valueOrNull?.name ?? '';
    final competition = compAsync.valueOrNull;
    final isDraft = competition?.status == CompetitionStatus.draft;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      competition,
    );
    final canManage = canEdit && isDraft;

    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 1,
            shadowColor: AppColors.black.withValues(alpha: 0.08),
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.line, width: 1),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${round.number}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              round.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              round.type.label,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (canManage) ...[
                    KicksterButton(
                      label: 'Editar dados',
                      icon: Icons.edit_outlined,
                      onPressed: () =>
                          context.go('/rounds/${round.id}/edit', extra: round),
                    ),
                    const SizedBox(height: 8),
                    // Issue #347: confrontos/jogos geridos via contexto da
                    // competição (rodada → jogos), sem atalho global da home.
                    KicksterButton(
                      label: 'Confrontos',
                      icon: Icons.sports,
                      variant: KicksterButtonVariant.outline,
                      onPressed: () {
                        ref.read(selectedCompetitionProvider.notifier).state =
                            round.competitionId;
                        ref.read(selectedRoundProvider.notifier).state =
                            round.id;
                        context.go('/games');
                      },
                    ),
                  ] else
                    EditRestrictionNote(
                      message: !isDraft
                          ? 'Competição publicada — as rodadas estão '
                                'travadas.'
                          : 'Apenas o criador da competição pode editar '
                                'esta rodada.',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppInfoCard(
            children: [
              AppInfoRow(label: 'Número', value: '${round.number}'),
              AppInfoRow(label: 'Nome', value: round.name),
              AppInfoRow(label: 'Tipo', value: round.type.label),
              AppInfoRow(label: 'Competição', value: competitionName),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Criado em ${formatBrDate(round.createdAt)}'
            '${round.updatedAt != null ? ' • Atualizado em ${formatBrDate(round.updatedAt)}' : ''}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
