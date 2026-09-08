import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';
import 'package:flag_admin_web/src/providers/providers.dart';

/// Tela de Detalhes da Competição (ADR-001 / Kickster Design System).
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  const CompetitionDetailScreen({
    super.key,
    required this.id,
    this.competition,
  });

  final String id;
  final Competition? competition;

  @override
  ConsumerState<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(competitionDetailViewModelProvider(widget.id))
          .load(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(competitionDetailViewModelProvider(widget.id));
    final comp = vm.competition ?? widget.competition;
    final user = ref.watch(authControllerProvider.select((a) => a.state.user));
    final canWrite = user != null;
    final organizationsAsync = ref.watch(organizationsProvider);

    if (vm.isLoading && comp == null) {
      return const AppScreen(
        title: 'Competição',
        body: AppLoading(message: 'Carregando detalhes...'),
      );
    }

    if (comp == null) {
      return AppScreen(
        title: 'Competição',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vm.errorMessage ?? 'Competição não encontrada.',
                style: const TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 12),
              KicksterButton(
                label: 'Voltar',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

        final orgs = organizationsAsync.valueOrNull;
        final matchedOrg = orgs?.where((o) => o.id == comp.organizationId).firstOrNull;
        final orgName = (comp.organizationName != null && comp.organizationName!.trim().isNotEmpty)
            ? comp.organizationName!
            : (matchedOrg?.tradeName ?? matchedOrg?.legalName);

        return AppScreen(
          title: comp.displayName,
          breadcrumb: [
            const BreadcrumbItem(AppStrings.home, route: '/'),
            const BreadcrumbItem('Competições', route: '/competitions'),
            BreadcrumbItem(comp.displayName),
          ],
          body: AppLayout.detail(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ações superiores
                  Row(
                    children: [
                      _buildStatusChip(comp.status),
                      const Spacer(),
                      if (canWrite)
                        KicksterButton(
                          label: 'Editar',
                          icon: Icons.edit_outlined,
                          onPressed: () async {
                            await context.push(
                              '/competitions/${comp.id}/edit',
                              extra: comp,
                            );
                            if (context.mounted) {
                              ref
                                  .read(competitionDetailViewModelProvider(widget.id))
                                  .load(forceRefresh: true);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card de Informações Gerais
                  Card(
                    elevation: 0,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.line, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comp.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                        ),
                        if (orgName != null && orgName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Organização Promotora: $orgName',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const Divider(height: 32),
                        Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            _buildInfoItem(
                              icon: Icons.date_range_outlined,
                              label: 'Temporada',
                              value: comp.season,
                            ),
                            _buildInfoItem(
                              icon: Icons.account_tree_outlined,
                              label: 'Formato',
                              value: comp.tournamentFormat.label,
                            ),
                            if (comp.groupingType != null)
                              _buildInfoItem(
                                icon: Icons.grid_view_outlined,
                                label: 'Agrupamento',
                                value: comp.groupingType!.label,
                              ),
                            if (comp.modality != null)
                              _buildInfoItem(
                                icon: Icons.sports_football_outlined,
                                label: 'Modalidade',
                                value: comp.modality!.label,
                              ),
                            if (comp.gender != null)
                              _buildInfoItem(
                                icon: Icons.people_outline,
                                label: 'Gênero',
                                value: comp.gender!,
                              ),
                            if (comp.ageGroup != null)
                              _buildInfoItem(
                                icon: Icons.cake_outlined,
                                label: 'Categoria',
                                value: comp.ageGroup!,
                              ),
                          ],
                        ),
                        if (comp.description != null &&
                            comp.description!.isNotEmpty) ...[
                          const Divider(height: 32),
                          const Text(
                            'Descrição / Regulamento:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comp.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (comp.groupingConfig != null &&
                            (comp.groupingConfig!.groups.isNotEmpty ||
                                comp.groupingConfig!.conferences.isNotEmpty)) ...[
                          const Divider(height: 32),
                          Text(
                            comp.groupingType == GroupingType.groups
                                ? 'Grupos Definidos:'
                                : 'Conferências & Divisões:',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (comp.groupingType == GroupingType.groups)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: comp.groupingConfig!.groups.map((g) {
                                return Chip(
                                  backgroundColor: AppColors.surfaceMuted,
                                  avatar: const Icon(Icons.grid_view_outlined,
                                      size: 16, color: AppColors.primary),
                                  label: Text(
                                    g.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  side: const BorderSide(color: AppColors.line),
                                );
                              }).toList(),
                            )
                          else if (comp.groupingType == GroupingType.conferences)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  comp.groupingConfig!.conferences.map((c) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.account_tree_outlined,
                                          size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (c.divisions.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${c.divisions.map((d) => d.name).join(', ')})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Seções de Navegação do Torneio
                KicksterSectionTitle(
                  title: 'Gestão Esportiva do Torneio',
                  icon: Icons.dashboard_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: KicksterCard(
                        icon: Icons.groups_outlined,
                        title: 'Equipes Inscritas',
                        subtitle: 'Homologação e elenco de agremiações',
                        onTap: () {
                          context.push(
                            '/competitions/${comp.id}/teams',
                            extra: comp,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KicksterCard(
                        icon: Icons.calendar_month_outlined,
                        title: 'Tabela & Confrontos',
                        subtitle: 'Rodadas, praças e datas de jogos',
                        onTap: () {
                          context.push('/rounds?competitionId=${comp.id}');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(CompetitionStatus status) {
    final chipType = switch (status) {
      CompetitionStatus.registrationOpen => KicksterStatusChipType.success,
      CompetitionStatus.ongoing => KicksterStatusChipType.pending,
      CompetitionStatus.draft => KicksterStatusChipType.unpaid,
      CompetitionStatus.finished => KicksterStatusChipType.refund,
      CompetitionStatus.disabled || CompetitionStatus.registrationClosed =>
        KicksterStatusChipType.failed,
      _ => KicksterStatusChipType.unpaid,
    };

    return KicksterStatusChip(
      status: chipType,
      label: status.label,
    );
  }
}
