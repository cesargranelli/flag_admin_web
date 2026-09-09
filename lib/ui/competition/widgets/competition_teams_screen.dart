import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/domain/models/competition_team.dart';
import 'package:flag_admin_web/domain/models/team.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/competition_team_status.dart';
import 'package:flag_admin_web/src/domain/enums/grouping_type.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/competition/view_models/competition_teams_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela de Gestão e Homologação de Equipes em Competições (ADR-001 / Kickster DS).
class CompetitionTeamsScreen extends ConsumerStatefulWidget {
  const CompetitionTeamsScreen({
    super.key,
    required this.competitionId,
    this.competition,
  });

  final String competitionId;
  final Competition? competition;

  @override
  ConsumerState<CompetitionTeamsScreen> createState() =>
      _CompetitionTeamsScreenState();
}

class _CompetitionTeamsScreenState
    extends ConsumerState<CompetitionTeamsScreen> {
  final _searchController = TextEditingController();

  CompetitionTeamsParam get _param => CompetitionTeamsParam(
        competitionId: widget.competitionId,
        competition: widget.competition,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(competitionTeamsViewModelProvider(_param)).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(competitionTeamsViewModelProvider(_param));
    final user = ref.watch(authControllerProvider.select((a) => a.state.user));
    final canWrite = user != null;

    final compName = widget.competition?.displayName ?? 'Competição';

    return AppScreen(
      title: 'Equipes Inscritas: $compName',
      scrollable: false,
      breadcrumb: [
        const BreadcrumbItem(AppStrings.home, route: '/'),
        const BreadcrumbItem('Competições', route: '/competitions'),
        BreadcrumbItem(compName, route: '/competitions/${widget.competitionId}'),
        const BreadcrumbItem('Equipes'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              if (canWrite)
                KicksterButton(
                  label: 'Inscrever Equipe',
                  icon: Icons.add,
                  onPressed: () => _showEnrollModal(context, vm),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildBody(context, vm, canWrite),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CompetitionTeamsViewModel vm,
    bool canWrite,
  ) {
    if (vm.isLoading && vm.teams.isEmpty) {
      return const AppLoading(message: 'Carregando equipes...');
    }

    if (vm.errorMessage != null && vm.teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.errorMessage!,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 12),
            KicksterButton(
              label: 'Tentar novamente',
              onPressed: () => vm.load(forceRefresh: true),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilters(context, vm),
        const SizedBox(height: 16),
        Expanded(
          child: vm.filteredTeams.isEmpty
              ? _buildEmptyState(vm, canWrite)
              : _buildList(context, vm, canWrite),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, CompetitionTeamsViewModel vm) {
    // Opções de agrupamento disponíveis
    final availableGroups = <String>[];
    for (final t in vm.teams) {
      if (t.groupName != null &&
          t.groupName!.isNotEmpty &&
          !availableGroups.contains(t.groupName!)) {
        availableGroups.add(t.groupName!);
      }
      if (t.conferenceName != null &&
          t.conferenceName!.isNotEmpty &&
          !availableGroups.contains(t.conferenceName!)) {
        availableGroups.add(t.conferenceName!);
      }
    }

    return Row(
      children: [
        Expanded(
          child: KicksterSearchField(
            controller: _searchController,
            hint: 'Buscar por equipe, agremiação ou grupo...',
            onChanged: vm.setSearchQuery,
          ),
        ),
        const SizedBox(width: 12),
        // Dropdown de Status (PENDING, APPROVED, REJECTED)
        SizedBox(
          width: 200,
          child: KicksterDropdown<CompetitionTeamStatus?>(
            label: '',
            value: vm.statusFilter,
            values: const [
              null,
              CompetitionTeamStatus.pending,
              CompetitionTeamStatus.approved,
              CompetitionTeamStatus.rejected,
            ],
            labels: const [
              'Todos os status',
              'Pendente',
              'Homologado',
              'Rejeitado',
            ],
            icons: const [
              Icons.filter_list,
              Icons.schedule,
              Icons.check_circle_outline,
              Icons.cancel_outlined,
            ],
            onChanged: vm.setStatusFilter,
          ),
        ),
        if (availableGroups.isNotEmpty) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: KicksterDropdown<String?>(
              label: '',
              value: vm.groupFilter,
              values: [null, ...availableGroups],
              labels: ['Todos os grupos', ...availableGroups],
              icons: [
                Icons.grid_view_outlined,
                ...availableGroups.map((_) => Icons.shield_outlined),
              ],
              onChanged: vm.setGroupFilter,
            ),
          ),
        ],
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Atualizar',
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: () => vm.load(forceRefresh: true),
        ),
      ],
    );
  }

  Widget _buildEmptyState(CompetitionTeamsViewModel vm, bool canWrite) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_outlined,
            size: 64,
            color: AppColors.disabled,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma equipe encontrada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inscreva equipes para compor a tabela e disputar os jogos.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (canWrite) ...[
            const SizedBox(height: 16),
            KicksterButton(
              label: 'Inscrever Equipe',
              icon: Icons.add,
              onPressed: () => _showEnrollModal(context, vm),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    CompetitionTeamsViewModel vm,
    bool canWrite,
  ) {
    final list = vm.filteredTeams;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        return RefreshIndicator(
          onRefresh: () => vm.load(forceRefresh: true),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 96,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _buildTeamCard(context, list[index], vm, canWrite);
            },
          ),
        );
      },
    );
  }

  Widget _buildTeamCard(
    BuildContext context,
    CompetitionTeam ct,
    CompetitionTeamsViewModel vm,
    bool canWrite,
  ) {
    final isBusy = vm.actionInProgressTeamId == ct.teamId;

    final subtitleParts = <String>[
      if (ct.organizationName != null && ct.organizationName!.isNotEmpty)
        ct.organizationName!,
      if (ct.groupName != null && ct.groupName!.isNotEmpty)
        'Grupo: ${ct.groupName}',
      if (ct.conferenceName != null && ct.conferenceName!.isNotEmpty)
        'Conf: ${ct.conferenceName}',
      if (ct.divisionName != null && ct.divisionName!.isNotEmpty)
        'Div: ${ct.divisionName}',
      if (ct.seedNumber != null) 'Seed #${ct.seedNumber}',
    ];

    return KicksterCard(
      icon: Icons.shield_outlined,
      title: ct.teamName,
      subtitle: subtitleParts.join(' • '),
      onTap: () => _showAllocationModal(context, vm, ct),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBusy)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          _buildStatusBadge(ct.status),
          const SizedBox(width: 8),
          if (canWrite)
            KicksterMenuAnchor(
              triggerLabel: 'Ações de ${ct.teamName}',
              alignment: Alignment.topRight,
              width: 230,
              trigger: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              items: [
                if (ct.status != CompetitionTeamStatus.approved)
                  KicksterMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 18, color: AppColors.success),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Homologar Equipe',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await vm.approveTeam(ct.teamId);
                    },
                  ),
                if (ct.status != CompetitionTeamStatus.rejected)
                  KicksterMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            size: 18, color: AppColors.warning),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Rejeitar Inscrição',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await vm.rejectTeam(ct.teamId);
                    },
                  ),
                KicksterMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.groups_outlined,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Elenco na Competição',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push(
                      '/teams/${ct.teamId}/roster',
                      extra: Team(
                        id: ct.teamId,
                        name: ct.teamName,
                        shortName: ct.teamShortName,
                        logoUrl: ct.teamLogoUrl,
                        organizationId: ct.organizationId ?? '',
                      ),
                    );
                  },
                ),
                KicksterMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.tune_outlined,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Alocar Grupo / Seed',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showAllocationModal(context, vm, ct),
                ),
                KicksterMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppColors.danger),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Remover da Competição',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final ok = await showKicksterConfirm(
                      context: context,
                      title: 'Remover Equipe',
                      content:
                          'Deseja remover "${ct.teamName}" desta competição?',
                      confirmLabel: 'Remover',
                      danger: true,
                    );
                    if (ok == true) {
                      await vm.removeTeam(ct.teamId);
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CompetitionTeamStatus status) {
    final chipType = switch (status) {
      CompetitionTeamStatus.approved => KicksterStatusChipType.success,
      CompetitionTeamStatus.pending => KicksterStatusChipType.pending,
      CompetitionTeamStatus.rejected => KicksterStatusChipType.failed,
    };

    return KicksterStatusChip(
      status: chipType,
      label: status.label,
    );
  }

  void _showEnrollModal(BuildContext context, CompetitionTeamsViewModel vm) {
    final availableTeams = vm.availableTeamsToEnroll;
    if (availableTeams.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Sem Equipes Disponíveis',
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Todas as equipes cadastradas já estão inscritas nesta competição.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            KicksterButton(
              label: 'OK',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    String? selectedTeamId = availableTeams.first['id'] as String;
    String? selectedGroup;
    String? selectedConference;
    String? selectedDivision;
    final comp = widget.competition;
    final isGroups = comp?.groupingType == GroupingType.groups;
    final isConferences = comp?.groupingType == GroupingType.conferences;

    // Grupos configurados na competição ou já presentes nas equipes
    final configGroups = (comp?.groupingConfig?.groups ?? [])
        .map((g) => g.name)
        .where((n) => n.trim().isNotEmpty)
        .toList();
    if (configGroups.isEmpty) {
      for (final t in vm.teams) {
        if (t.groupName != null &&
            t.groupName!.trim().isNotEmpty &&
            !configGroups.contains(t.groupName!.trim())) {
          configGroups.add(t.groupName!.trim());
        }
      }
    }

    final configConferences = comp?.groupingConfig?.conferences ?? [];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Inscrever Equipe',
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KicksterDropdown<String?>(
                    label: 'Selecione a Equipe',
                    value: selectedTeamId,
                    values: availableTeams.map((t) => t['id'] as String?).toList(),
                    labels: availableTeams.map((t) {
                      final club = (t['clubName'] as String?)?.trim();
                      final clubSuffix = (club != null && club.isNotEmpty) ? ' ($club)' : '';
                      return '${t['name'] ?? ''}$clubSuffix';
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedTeamId = val),
                  ),
                  if (selectedTeamId != null) ...[
                    Builder(builder: (_) {
                      final selTeam = availableTeams
                          .where((t) => t['id'] == selectedTeamId)
                          .firstOrNull;
                      final club = (selTeam?['clubName'] as String?)?.trim() ?? 'Não vinculada';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Agremiação: $club',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                  if (isGroups || configGroups.isNotEmpty) ...[
                    KicksterDropdown<String?>(
                      label: 'Grupo (Opcional)',
                      value: selectedGroup,
                      values: [null, ...configGroups],
                      labels: ['Sem Grupo Inicial', ...configGroups],
                      onChanged: (val) => setModalState(() => selectedGroup = val),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isConferences && configConferences.isNotEmpty) ...[
                    KicksterDropdown<String?>(
                      label: 'Conferência (Opcional)',
                      value: selectedConference,
                      values: [null, ...configConferences.map((c) => c.name)],
                      labels: [
                        'Sem Conferência Inicial',
                        ...configConferences.map((c) => c.name),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          selectedConference = val;
                          selectedDivision = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (selectedConference != null) ...[
                      Builder(builder: (_) {
                        final confObj = configConferences
                            .where((c) => c.name == selectedConference)
                            .firstOrNull;
                        final divisions = confObj?.divisions ?? [];
                        if (divisions.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            KicksterDropdown<String?>(
                              label: 'Divisão (Opcional)',
                              value: selectedDivision,
                              values: [null, ...divisions.map((d) => d.name)],
                              labels: [
                                'Sem Divisão Inicial',
                                ...divisions.map((d) => d.name),
                              ],
                              onChanged: (val) =>
                                  setModalState(() => selectedDivision = val),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                    ],
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 24,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vincular Elenco Base',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'A equipe manterá o plantel ativo pronto para convocação nos jogos.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: AppColors.success,
                        ),
                      ],
                    ),
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
              label: 'Confirmar Inscrição',
              onPressed: selectedTeamId == null
                  ? null
                  : () async {
                      Navigator.of(dialogCtx).pop();
                      // Atribui seed automático sequencial baseado na ordem de inscrição
                      final maxSeed = vm.teams.fold<int>(
                        0,
                        (max, t) => (t.seedNumber ?? 0) > max ? t.seedNumber! : max,
                      );
                      final autoSeed = maxSeed > 0 ? maxSeed + 1 : vm.teams.length + 1;

                      await vm.enrollTeam(
                        teamId: selectedTeamId!,
                        groupName: selectedGroup,
                        conferenceName: selectedConference,
                        divisionName: selectedDivision,
                        seedNumber: autoSeed,
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showAllocationModal(
    BuildContext context,
    CompetitionTeamsViewModel vm,
    CompetitionTeam ct,
  ) {
    String? selectedGroup = ct.groupName;
    String? selectedConference = ct.conferenceName;
    String? selectedDivision = ct.divisionName;
    final seedController =
        TextEditingController(text: ct.seedNumber?.toString() ?? '');

    final comp = widget.competition;
    final isGroups = comp?.groupingType == GroupingType.groups;
    final isConferences = comp?.groupingType == GroupingType.conferences;

    // Coleta os grupos oficiais da competição ou pré-existentes
    final configGroups = (comp?.groupingConfig?.groups ?? [])
        .map((g) => g.name)
        .where((n) => n.trim().isNotEmpty)
        .toList();
    if (configGroups.isEmpty) {
      for (final t in vm.teams) {
        if (t.groupName != null &&
            t.groupName!.trim().isNotEmpty &&
            !configGroups.contains(t.groupName!.trim())) {
          configGroups.add(t.groupName!.trim());
        }
      }
    }
    if (selectedGroup != null &&
        selectedGroup.isNotEmpty &&
        !configGroups.contains(selectedGroup)) {
      configGroups.add(selectedGroup);
    }

    final configConferences = comp?.groupingConfig?.conferences ?? [];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Alocar: ${ct.teamName}',
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isGroups || configGroups.isNotEmpty) ...[
                    KicksterDropdown<String?>(
                      label: 'Grupo',
                      value: selectedGroup,
                      values: [null, ...configGroups],
                      labels: ['Sem Grupo', ...configGroups],
                      onChanged: (val) => setModalState(() => selectedGroup = val),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isConferences && configConferences.isNotEmpty) ...[
                    KicksterDropdown<String?>(
                      label: 'Conferência',
                      value: selectedConference,
                      values: [null, ...configConferences.map((c) => c.name)],
                      labels: [
                        'Sem Conferência',
                        ...configConferences.map((c) => c.name),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          selectedConference = val;
                          selectedDivision = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (selectedConference != null) ...[
                      Builder(builder: (_) {
                        final confObj = configConferences
                            .where((c) => c.name == selectedConference)
                            .firstOrNull;
                        final divisions = confObj?.divisions ?? [];
                        if (divisions.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            KicksterDropdown<String?>(
                              label: 'Divisão',
                              value: selectedDivision,
                              values: [null, ...divisions.map((d) => d.name)],
                              labels: [
                                'Sem Divisão',
                                ...divisions.map((d) => d.name),
                              ],
                              onChanged: (val) =>
                                  setModalState(() => selectedDivision = val),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                    ],
                  ],
                  KicksterInput(
                    controller: seedController,
                    label: 'Seed / Chaveamento',
                    hintText: 'Ex: 1, 2, 3...',
                    keyboardType: TextInputType.number,
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
              label: 'Salvar Alocação',
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final seed = int.tryParse(seedController.text.trim());
                await vm.updateAllocation(
                  teamId: ct.teamId,
                  groupName: selectedGroup,
                  conferenceName: selectedConference,
                  divisionName: selectedDivision,
                  seedNumber: seed,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
