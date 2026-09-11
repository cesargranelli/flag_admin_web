import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import '../view_models/organization_view_model.dart';

/// Screen principal de listagem de Organizações (camada Views - ADR-001 / MVVM).
///
/// Apresenta os dados e despacha comandos para o [OrganizationViewModel].
/// Não contém lógica de negócio nem chamadas diretas a APIs REST.
class OrganizationListScreen extends ConsumerStatefulWidget {
  const OrganizationListScreen({super.key});

  @override
  ConsumerState<OrganizationListScreen> createState() =>
      _OrganizationListScreenState();
}

class _OrganizationListScreenState extends ConsumerState<OrganizationListScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _searchController;
  String? _lastActivePath;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final vm = ref.read(organizationViewModelProvider);
    _searchController = TextEditingController(text: vm.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(organizationViewModelProvider).load(forceRefresh: true);
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
    if (currentPath == '/organizations') {
      ref
          .read(organizationViewModelProvider)
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
    if (currentPath == '/organizations' && _lastActivePath != currentPath) {
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
    final vm = ref.watch(organizationViewModelProvider);
    final userRole = ref.watch(
      authControllerProvider.select((a) => a.state.user?.role),
    );
    final canWrite =
        userRole == UserRole.admin ||
        userRole == UserRole.organizer ||
        userRole == UserRole.manager ||
        userRole == UserRole.adminLiga;
    final isAdmin = userRole == UserRole.admin;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return AppScreen(
          title: AppStrings.organizations,
          scrollable: false,
          breadcrumb: const [
            BreadcrumbItem(AppStrings.home, route: '/'),
            BreadcrumbItem(AppStrings.organizations),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de ações superior
              if (canWrite)
                Row(
                  children: [
                    const Spacer(),
                    KicksterButton(
                      label: 'Novo',
                      icon: Icons.add,
                      onPressed: () {
                        context.go('/organizations/new');
                      },
                    ),
                  ],
                ),
              if (canWrite) const SizedBox(height: 16),
              // Conteúdo principal reagindo ao estado do ViewModel
              Expanded(child: _buildBody(context, vm, canWrite, isAdmin)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrganizationViewModel vm,
    bool canWrite,
    bool isAdmin,
  ) {
    if (vm.isLoading && vm.organizations.isEmpty) {
      return const AppLoading(message: 'Carregando organizações...');
    }

    if (vm.errorMessage != null && vm.organizations.isEmpty) {
      return AppErrorState(
        message: 'Não foi possível carregar as organizações',
        onRetry: () => vm.load(forceRefresh: true),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilters(context, vm, isAdmin),
        const SizedBox(height: 16),
        Expanded(
          child: vm.filteredOrganizations.isEmpty
              ? _buildEmptyState(vm)
              : _buildList(context, vm, canWrite),
        ),
      ],
    );
  }

  /// Barra de pesquisa e filtro seguindo o padrão Kickster (idêntica à de Agremiações).
  Widget _buildFilters(
    BuildContext context,
    OrganizationViewModel vm,
    bool isAdmin,
  ) {
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
          child: KicksterDropdown<OrganizationType?>(
            label: '',
            value: vm.typeFilter,
            values: [null, ...OrganizationType.values],
            labels: [
              'Todos os tipos',
              ...OrganizationType.values.map((t) => t.label),
            ],
            icons: [null, ...OrganizationType.values.map(organizationTypeIcon)],
            onChanged: vm.setTypeFilter,
          ),
        ),
        if (isAdmin) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: vm.showDisabled
                ? 'Ocultar organizações desativadas'
                : 'Exibir organizações desativadas',
            child: IconButton(
              isSelected: vm.showDisabled,
              selectedIcon: const Icon(Icons.visibility),
              icon: const Icon(Icons.visibility_off_outlined),
              onPressed: () => vm.setShowDisabled(!vm.showDisabled),
            ),
          ),
        ],
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

  Widget _buildEmptyState(OrganizationViewModel vm) {
    final hasFilters = vm.searchQuery.isNotEmpty || vm.typeFilter != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.business_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'Nenhuma organização encontrada para os filtros aplicados.'
                : 'Nenhuma organização cadastrada.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Lista em colunas responsivas com o padrão Kickster (1, 2 ou 3 colunas).
  Widget _buildList(
    BuildContext context,
    OrganizationViewModel vm,
    bool canWrite,
  ) {
    final list = vm.filteredOrganizations;
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

  Widget _buildCard(
    BuildContext context,
    Organization organization,
    OrganizationViewModel vm,
    bool canWrite,
  ) {
    final isDisabled = organization.status == OrganizationStatus.inactive;
    final isBusy = vm.actionInProgressId == organization.id;

    return KicksterCard(
      imageUrl: organization.logoUrl,
      icon: organizationTypeIcon(organization.organizationType),
      title: organization.tradeName,
      subtitle: organization.legalName,
      onTap: () async {
        context.go('/organizations/${organization.id}', extra: organization);
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
          if (isDisabled)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: KicksterBadge(
                label: 'Desativada',
                color: AppColors.danger,
              ),
            ),
          if (canWrite)
            KicksterMenuAnchor(
              triggerLabel: 'Ações de ${organization.tradeName}',
              alignment: Alignment.topRight,
              width: 170,
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
                    context.go(
                      '/organizations/${organization.id}/edit',
                      extra: organization,
                    );
                  },
                ),
                if (!isDisabled)
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
                        title: 'Excluir organização',
                        content:
                            'Deseja realmente excluir "${organization.tradeName}"?',
                        confirmLabel: 'Excluir',
                        danger: true,
                      );
                      if (ok == true && context.mounted) {
                        final success = await vm.delete(organization.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Organização excluída com sucesso.'
                                    : 'Não foi possível excluir a organização.',
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
                if (isDisabled)
                  KicksterMenuItem(
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Reativar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final success = await vm.reactivate(organization.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Organização reativada.'
                                  : 'Não foi possível reativar a organização.',
                            ),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        );
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
