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

class _OrganizationListScreenState extends ConsumerState<OrganizationListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final vm = ref.read(organizationViewModelProvider);
    _searchController = TextEditingController(text: vm.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(organizationViewModelProvider).load();
    });
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
                    onPressed: () => context.go('/organizations/new'),
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

    if (vm.organizations.isEmpty) {
      return KicksterEmptyState(
        icon: Icons.business,
        message: 'Nenhuma organização cadastrada',
        description: 'Crie a primeira organização para começar a usar.',
        action: KicksterButton(
          label: 'Criar organização',
          icon: Icons.add,
          onPressed: () => context.go('/organizations/new'),
        ),
      );
    }

    return AppEntityListScreen<Organization>(
      items: vm.organizations,
      cardBuilder: (org) => _buildCard(context, org, vm, isAdmin),
      searchField: _searchController,
      emptyMessage: 'Nenhuma organização encontrada',
      searchWidth: 220,
      filter: (all, query) {
        if (query != vm.searchQuery) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.setSearchQuery(query);
          });
        }
        return vm.filteredOrganizations;
      },
      toolbarLeading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          if (isAdmin) ...[
            Tooltip(
              message: 'Exibir organizações desativadas',
              child: IconButton(
                isSelected: vm.showDisabled,
                selectedIcon: const Icon(Icons.visibility),
                icon: const Icon(Icons.visibility_off_outlined),
                tooltip: 'Desativadas',
                onPressed: () => vm.setShowDisabled(!vm.showDisabled),
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 260,
            child: KicksterDropdown<OrganizationType?>(
              label: 'Filtrar por tipo',
              value: vm.typeFilter,
              values: [null, ...OrganizationType.values],
              labels: [
                'Todas as organizações',
                ...OrganizationType.values.map((t) => t.label),
              ],
              icons: [
                null,
                ...OrganizationType.values.map(organizationTypeIcon),
              ],
              onChanged: (value) => vm.setTypeFilter(value),
            ),
          ),
        ],
      ),
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
      onTap: () => context.push(
        '/organizations/${organization.id}',
        extra: organization,
      ),
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
            Padding(
              padding: const EdgeInsets.only(right: 4),
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
                    content: '  ficará invisível '
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
                                ? ' desativada.'
                                : 'Não foi possível desativar a organização.',
                          ),
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
                              ? ' reativada.'
                              : 'Não foi possível reativar a organização.',
                        ),
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
