import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/domain/models/competition.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/enums/competition_status.dart';
import 'package:flag_admin_web/src/domain/enums/user_role.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import '../view_models/competition_list_view_model.dart';

/// Tela de Listagem de Competições e Campeonatos (ADR-001 / Kickster Design System).
class CompetitionListScreen extends ConsumerStatefulWidget {
  const CompetitionListScreen({super.key});

  @override
  ConsumerState<CompetitionListScreen> createState() =>
      _CompetitionListScreenState();
}

class _CompetitionListScreenState extends ConsumerState<CompetitionListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(competitionListViewModelProvider).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(competitionListViewModelProvider);
    final user = ref.watch(authControllerProvider.select((a) => a.state.user));
    final canWrite = user?.role == UserRole.admin;

    return AppScreen(
      title: 'Competições',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem('Competições'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              if (canWrite)
                KicksterButton(
                  label: 'Nova Competição',
                  icon: Icons.add,
                  onPressed: () async {
                    await context.push('/competitions/new');
                    if (context.mounted) {
                      vm.load(forceRefresh: true);
                    }
                  },
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
    CompetitionListViewModel vm,
    bool canWrite,
  ) {
    if (vm.isLoading && vm.competitions.isEmpty) {
      return const AppLoading(message: 'Carregando competições...');
    }

    if (vm.errorMessage != null && vm.competitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(vm.errorMessage!),
            const SizedBox(height: 16),
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
          child: vm.filteredCompetitions.isEmpty
              ? _buildEmptyState(vm)
              : _buildList(context, vm, canWrite),
        ),
      ],
    );
  }

  /// Barra de pesquisa e filtros no padrão Kickster.
  Widget _buildFilters(BuildContext context, CompetitionListViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.fieldBorderLight),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: vm.setSearchQuery,
                        decoration: const InputDecoration(
                          hintText: 'Buscar por nome do torneio ou organização...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          vm.setSearchQuery('');
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Exibir desativados',
              child: IconButton(
                isSelected: vm.showDisabled,
                selectedIcon: const Icon(Icons.visibility),
                icon: const Icon(Icons.visibility_off_outlined),
                onPressed: vm.toggleShowDisabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Filtro por Temporada
              if (vm.availableSeasons.isNotEmpty) ...[
                _buildFilterChip(
                  label: 'Todas Temporadas',
                  isSelected: vm.seasonFilter == null,
                  onSelected: () => vm.setSeasonFilter(null),
                ),
                for (final s in vm.availableSeasons)
                  _buildFilterChip(
                    label: 'Temporada ',
                    isSelected: vm.seasonFilter == s,
                    onSelected: () => vm.setSeasonFilter(s),
                  ),
                const SizedBox(width: 12),
              ],
              // Filtro por Status
              _buildFilterChip(
                label: 'Todos Status',
                isSelected: vm.statusFilter == null,
                onSelected: () => vm.setStatusFilter(null),
              ),
              for (final st in [
                CompetitionStatus.registrationOpen,
                CompetitionStatus.ongoing,
                CompetitionStatus.draft,
                CompetitionStatus.finished,
              ])
                _buildFilterChip(
                  label: st.label,
                  isSelected: vm.statusFilter == st,
                  onSelected: () => vm.setStatusFilter(st),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.line,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(CompetitionListViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: AppColors.disabled,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma competição encontrada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tente ajustar seus filtros ou crie uma nova competição.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    CompetitionListViewModel vm,
    bool canWrite,
  ) {
    final list = vm.filteredCompetitions;
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
              mainAxisExtent: 110,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _buildCard(context, list[index], vm, canWrite);
            },
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    Competition comp,
    CompetitionListViewModel vm,
    bool canWrite,
  ) {
    final isBusy = vm.actionInProgressId == comp.id;
    final isDisabled = comp.status == CompetitionStatus.disabled;

    final subtitle = [
      if (comp.organizationName != null && comp.organizationName!.isNotEmpty)
        comp.organizationName!,
      'Temporada ',
      if (comp.modality != null) comp.modality!.label,
    ].join(' • ');

    return KicksterCard(
      icon: Icons.emoji_events_outlined,
      title: comp.name,
      subtitle: subtitle,
      onTap: () async {
        await context.push(
          '/competitions/',
          extra: comp,
        );
        if (context.mounted) {
          vm.load(forceRefresh: true);
        }
      },
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
          _buildStatusBadge(comp.status),
          const SizedBox(width: 8),
          if (canWrite)
            KicksterMenuAnchor(
              triggerLabel: 'Ações de ',
              alignment: Alignment.topRight,
              width: 180,
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
                KicksterMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await context.push(
                      '/competitions//edit',
                      extra: comp,
                    );
                    if (context.mounted) {
                      vm.load(forceRefresh: true);
                    }
                  },
                ),
                if (!isDisabled)
                  KicksterMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_off_outlined,
                            size: 18, color: AppColors.warning),
                        SizedBox(width: 10),
                        Text(
                          'Desativar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final ok = await showKicksterConfirm(
                        context: context,
                        title: 'Desativar competição',
                        content:
                            'Deseja desativar ""? Ela ficará oculta para os demais usuários.',
                        confirmLabel: 'Desativar',
                        danger: true,
                      );
                      if (ok == true) {
                        await vm.deactivate(comp);
                      }
                    },
                  ),
                if (isDisabled)
                  KicksterMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 18, color: AppColors.success),
                        SizedBox(width: 10),
                        Text(
                          'Reativar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await vm.reactivate(comp);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CompetitionStatus status) {
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
