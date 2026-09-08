import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/providers/providers.dart';

/// Tela de Detalhes da Competição (ADR-001 / Kickster Design System).
class CompetitionDetailScreen extends ConsumerWidget {
  const CompetitionDetailScreen({
    super.key,
    required this.id,
    this.competition,
  });

  final String id;
  final Competition? competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compAsync = ref.watch(competitionRepositoryProvider);
    final user = ref.watch(authControllerProvider.select((a) => a.state.user));
    final canWrite = user != null;

    return FutureBuilder<Competition>(
      future: competition != null
          ? Future.value(competition!)
          : compAsync.getCompetition(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            competition == null) {
          return const AppScreen(
            title: 'Competição',
            body: AppLoading(message: 'Carregando detalhes...'),
          );
        }

        final comp = snapshot.data ?? competition;
        if (comp == null) {
          return AppScreen(
            title: 'Competição',
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Competição não encontrada.'),
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
                        if (comp.organizationName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Organização Promotora: ',
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
                          // Navegar para módulo de equipes/inscrições com contexto da competição
                          context.push('/teams?competitionId=${comp.id}');
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
      },
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
