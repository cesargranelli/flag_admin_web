import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_detail_view_model.dart';

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
      ref
          .read(competitionDetailViewModelProvider(widget.id))
          .loadEnrollmentWindow();
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

                // Seção de Janela de Inscrição
                _buildEnrollmentWindowSection(vm, canWrite),

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
                        subtitle: 'Homologação e elencos das equipes esportivas',
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
                        subtitle: 'Rodadas e confrontos das equipes esportivas',
                        onTap: () {
                          context.push(
                            '/competitions/${comp.id}/games',
                            extra: comp,
                          );
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

  Widget _buildEnrollmentWindowSection(
    CompetitionDetailViewModel vm,
    bool canWrite,
  ) {
    final win = vm.enrollmentWindow;
    final isOpen = win?.isOpen ?? false;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOpen
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.line,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOpen ? Icons.event_available : Icons.event_busy,
                  size: 20,
                  color: isOpen ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpen
                            ? 'Inscrições Abertas'
                            : 'Inscrições Encerradas / Não Abertas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOpen ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                      if (win != null && isOpen) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Prazo: até ${win.endDate.day.toString().padLeft(2, "0")}/${win.endDate.month.toString().padLeft(2, "0")}/${win.endDate.year}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canWrite)
                  if (isOpen)
                    KicksterButton(
                      label: 'Encerrar Inscrições',
                      variant: KicksterButtonVariant.outline,
                      loading: vm.isSavingWindow,
                      onPressed: () async {
                        final ok = await showKicksterConfirm(
                          context: context,
                          title: 'Encerrar Inscrições',
                          content: 'Deseja encerrar o período de inscrição de equipes para esta competição?',
                          confirmLabel: 'Encerrar',
                          danger: true,
                        );
                        if (ok == true) {
                          await vm.closeEnrollmentWindow();
                        }
                      },
                    )
                  else
                    KicksterButton(
                      label: 'Abrir Inscrições',
                      icon: Icons.add,
                      variant: KicksterButtonVariant.outline,
                      onPressed: () => _showOpenEnrollmentWindowModal(context, vm),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenEnrollmentWindowModal(
    BuildContext context,
    CompetitionDetailViewModel vm,
  ) {
    final titleCtrl = TextEditingController(
      text: 'Inscrições ${vm.competition?.season ?? DateTime.now().year}',
    );
    final instructionsCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime(DateTime.now().year, 12, 31);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          String formatDate(DateTime d) =>
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Abrir Período de Inscrição de Equipes'),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Defina o prazo durante o qual agremiações poderão inscrever equipes nesta competição.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    KicksterInput(
                      label: 'Título do Período *',
                      controller: titleCtrl,
                      hintText: 'Ex: Inscrições 2026',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data de Início *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showAppCalendarDialog(
                                    context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setModalState(() => startDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border.all(color: AppColors.line),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatDate(startDate),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data de Encerramento *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showAppCalendarDialog(
                                    context,
                                    initialDate: endDate.isAfter(startDate) ? endDate : startDate,
                                    firstDate: startDate,
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setModalState(() => endDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border.all(color: AppColors.line),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatDate(endDate),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    KicksterInput(
                      label: 'Instruções e Requisitos (Opcional)',
                      controller: instructionsCtrl,
                      maxLines: 3,
                      hintText: 'Ex: Equipes devem apresentar elenco mínimo de 10 atletas.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              KicksterButton(
                label: 'Cancelar',
                variant: KicksterButtonVariant.text,
                onPressed: () => Navigator.of(dialogCtx).pop(),
              ),
              KicksterButton(
                label: 'Abrir Inscrições',
                variant: KicksterButtonVariant.primary,
                loading: vm.isSavingWindow,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (endDate.isBefore(startDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('A data de encerramento não pode ser anterior ao início.')),
                    );
                    return;
                  }
                  final ok = await vm.openEnrollmentWindow(
                    title: titleCtrl.text.trim(),
                    startDate: startDate,
                    endDate: endDate,
                    instructions: instructionsCtrl.text.trim().isEmpty ? null : instructionsCtrl.text.trim(),
                  );
                  if (ok && dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Período de inscrições aberto com sucesso!')),
                    );
                  }
                },
              ),
            ],
          );
        },
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
