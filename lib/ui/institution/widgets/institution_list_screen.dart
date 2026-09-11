import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import '../view_models/institution_view_model.dart';

/// Screen principal de Agremiações (camada Views - ADR-001 / MVVM).
///
/// Consome [InstitutionViewModel] e apresenta listagem com busca, filtro por tipo e layout Kickster.
class InstitutionListScreen extends ConsumerStatefulWidget {
  const InstitutionListScreen({super.key});

  @override
  ConsumerState<InstitutionListScreen> createState() =>
      _InstitutionListScreenState();
}

class _InstitutionListScreenState extends ConsumerState<InstitutionListScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _searchController;
  String? _lastActivePath;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final vm = ref.read(institutionViewModelProvider);
    _searchController = TextEditingController(text: vm.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(institutionViewModelProvider).load(forceRefresh: true);
    });
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    // Sincronização periódica em background (SWR a cada 25 segundos)
    _syncTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _revalidateIfActive(silent: true);
    });
  }

  void _revalidateIfActive({bool silent = true}) {
    if (!mounted) return;
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == '/institutions') {
      ref
          .read(institutionViewModelProvider)
          .load(forceRefresh: true, silent: silent);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _revalidateIfActive(silent: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == '/institutions' && _lastActivePath != currentPath) {
      _lastActivePath = currentPath;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _revalidateIfActive(silent: true);
      });
    } else {
      _lastActivePath = currentPath;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(institutionViewModelProvider);
    final userRole = ref.watch(
      authControllerProvider.select((a) => a.state.user?.role),
    );
    final canWrite =
        userRole == UserRole.admin ||
        userRole == UserRole.organizer ||
        userRole == UserRole.manager ||
        userRole == UserRole.adminLiga;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return AppScreen(
          title: AppStrings.institutions,
          scrollable: false,
          breadcrumb: const [
            BreadcrumbItem(AppStrings.home, route: '/'),
            BreadcrumbItem(AppStrings.institutions),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ações superiores
              if (canWrite)
                Row(
                  children: [
                    const Spacer(),
                    KicksterButton(
                      label: 'Nova Agremiação',
                      icon: Icons.add,
                      onPressed: () async {
                        context.go('/institutions/new');
                      },
                    ),
                  ],
                ),
              if (canWrite) const SizedBox(height: 16),
              Expanded(child: _buildBody(context, vm, canWrite)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    InstitutionViewModel vm,
    bool canWrite,
  ) {
    if (vm.isLoading && vm.institutions.isEmpty) {
      return const AppLoading(message: 'Carregando agremiações...');
    }

    if (vm.errorMessage != null && vm.institutions.isEmpty) {
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
          child: vm.filteredInstitutions.isEmpty
              ? _buildEmptyState(vm)
              : _buildList(context, vm, canWrite),
        ),
      ],
    );
  }

  /// Barra de pesquisa e filtro seguindo o padrão Kickster (Pill 52px, raio 24).
  Widget _buildFilters(BuildContext context, InstitutionViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: KicksterSearchField(
            controller: _searchController,
            hint: 'Buscar por nome...',
            onChanged: vm.setSearchQuery,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 240,
          child: KicksterDropdown<InstitutionType?>(
            label: '',
            value: vm.typeFilter,
            values: [null, ...InstitutionType.values],
            labels: [
              'Todos os tipos',
              ...InstitutionType.values.map((t) => t.label),
            ],
            icons: [null, ...InstitutionType.values.map(institutionTypeIcon)],
            onChanged: vm.setTypeFilter,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: vm.isRevalidating ? 'Sincronizando...' : 'Atualizar lista',
          child: IconButton(
            icon: vm.isRevalidating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: vm.isRevalidating
                ? null
                : () => vm.load(forceRefresh: true),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(InstitutionViewModel vm) {
    final hasFilters = vm.searchQuery.isNotEmpty || vm.typeFilter != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'Nenhuma agremiação encontrada para os filtros aplicados.'
                : 'Nenhuma agremiação cadastrada.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Lista em colunas responsivas no padrão Kickster (1, 2 ou 3 colunas).
  Widget _buildList(
    BuildContext context,
    InstitutionViewModel vm,
    bool canWrite,
  ) {
    final list = vm.filteredInstitutions;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width >= 1200) {
          crossAxisCount = 3;
        } else if (width >= 720) {
          crossAxisCount = 2;
        }

        return RefreshIndicator(
          onRefresh: () => vm.load(forceRefresh: true),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 96,
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

  /// Card padronizado com o formato do card de Organizações.
  Widget _buildCard(
    BuildContext context,
    Institution inst,
    InstitutionViewModel vm,
    bool canWrite,
  ) {
    final isBusy = vm.actionInProgressId == inst.id;

    final subtitle = inst.abbreviation != null && inst.abbreviation!.isNotEmpty
        ? '${inst.type.label} • ${inst.abbreviation}'
        : inst.type.label;

    return KicksterCard(
      icon: institutionTypeIcon(inst.type),
      imageUrl: inst.logoUrl,
      title: inst.tradeName.isNotEmpty ? inst.tradeName : inst.name,
      subtitle: subtitle,
      onTap: () async {
        context.go('/institutions/${inst.id}', extra: inst);
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
          if (canWrite)
            KicksterMenuAnchor(
              triggerLabel: 'Ações de ${inst.tradeName}',
              alignment: Alignment.topRight,
              width: 160,
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
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
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
                    context.go('/institutions/${inst.id}/edit', extra: inst);
                  },
                ),
                KicksterMenuItem(
                  child: const Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Excluir',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final ok = await showKicksterConfirm(
                      context: context,
                      title: 'Excluir agremiação',
                      content:
                          'Deseja realmente excluir "${inst.tradeName.isNotEmpty ? inst.tradeName : inst.name}"?',
                      confirmLabel: 'Excluir',
                      danger: true,
                    );
                    if (ok == true && context.mounted) {
                      final success = await vm.delete(inst.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Agremiação excluída com sucesso.'
                                  : 'Erro ao excluir: ${vm.errorMessage}',
                            ),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
