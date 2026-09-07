import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
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

class _OrganizationListScreenState
    extends ConsumerState<OrganizationListScreen> {
  late final TextEditingController _searchController;
  String? _lastActivePath;

  @override
  void initState() {
    super.initState();
    final vm = ref.read(organizationViewModelProvider);
    _searchController = TextEditingController(text: vm.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(organizationViewModelProvider).load(forceRefresh: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == '/organizations' && _lastActivePath != currentPath) {
      _lastActivePath = currentPath;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(organizationViewModelProvider).load(forceRefresh: true);
        }
      });
    } else {
      _lastActivePath = currentPath;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(organizationViewModelProvider);
    final isAdmin =
        ref.watch(authControllerProvider.select((a) => a.state.user?.role)) ==
        UserRole.admin;

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
              Row(
                children: [
                  const Spacer(),
                  KicksterButton(
                    label: 'Novo',
                    icon: Icons.add,
                    onPressed: () async {
                      await context.push('/organizations/new');
                      if (context.mounted) {
                        vm.load(forceRefresh: true);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Conteúdo principal reagindo ao estado do ViewModel
              Expanded(
                child: _buildBody(context, vm, isAdmin),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrganizationViewModel vm,
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
              : _buildList(context, vm, isAdmin),
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
            icons: [
              null,
              ...OrganizationType.values.map(organizationTypeIcon),
            ],
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
          message: 'Atualizar lista',
          child: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => vm.load(forceRefresh: true),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(OrganizationViewModel vm) {
    final hasFilters =
        vm.searchQuery.isNotEmpty || vm.typeFilter != null;
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

  /// Lista em 2 colunas responsivas com o mesmo padrão de Agremiações.
  Widget _buildList(
    BuildContext context,
    OrganizationViewModel vm,
    bool isAdmin,
  ) {
    final list = vm.filteredOrganizations;
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
              return _buildCard(context, list[index], vm, isAdmin);
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
    bool isAdmin,
  ) {
    final isDisabled = organization.status == OrganizationStatus.inactive;
    final isBusy = vm.actionInProgressId == organization.id;

    return KicksterCard(
      imageUrl: organization.logoUrl,
      icon: organizationTypeIcon(organization.organizationType),
      title: organization.tradeName,
      subtitle: organization.legalName,
      onTap: () async {
        await context.push(
          '/organizations/${organization.id}',
          extra: organization,
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
          if (isDisabled)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: KicksterBadge(
                label: 'Desativada',
                color: AppColors.danger,
              ),
            ),
          if (isAdmin)
            PopupMenuButton<String>(
              tooltip: 'Ações',
              enabled: !isBusy,
              onSelected: (value) async {
                if (value == 'deactivate') {
                  final ok = await showKicksterConfirm(
                    context: context,
                    title: 'Desativar organização',
                    content:
                        'A organização "${organization.tradeName}" ficará invisível '
                        'para os demais usuários até ser reativada.',
                    confirmLabel: 'Desativar',
                    danger: true,
                  );
                  if (ok == true && context.mounted) {
                    final success = await vm.delete(organization.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Organização desativada.'
                                : 'Não foi possível desativar a organização.',
                          ),
                          backgroundColor:
                              success ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }
                  }
                } else if (value == 'reactivate') {
                  final success = await vm.reactivate(organization.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Organização reativada.'
                              : 'Não foi possível reativar a organização.',
                        ),
                        backgroundColor:
                            success ? AppColors.success : AppColors.danger,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                if (!isDisabled)
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Text('Desativar'),
                  ),
                if (isDisabled)
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reativar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
