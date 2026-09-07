import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import '../view_models/institution_view_model.dart';

/// Screen principal de Agremiações (camada Views - ADR-001 / MVVM).
///
/// Consome [InstitutionViewModel] e apresenta listagem com busca e filtro por tipo.
class InstitutionsScreen extends ConsumerStatefulWidget {
  const InstitutionsScreen({super.key});

  @override
  ConsumerState<InstitutionsScreen> createState() => _InstitutionsScreenState();
}

class _InstitutionsScreenState extends ConsumerState<InstitutionsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final vm = ref.read(institutionViewModelProvider);
    _searchController = TextEditingController(text: vm.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(institutionViewModelProvider).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return AppColors.surfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(institutionViewModelProvider);
    final userRole =
        ref.watch(authControllerProvider.select((a) => a.state.user?.role));
    final canWrite = userRole == UserRole.admin ||
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
                      label: 'Nova',
                      icon: Icons.add,
                      onPressed: () => context.go('/institutions/new'),
                    ),
                  ],
                ),
              if (canWrite) const SizedBox(height: 16),
              Expanded(
                child: _buildBody(context, vm, canWrite),
              ),
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
      return AppErrorState(
        message: 'Não foi possível carregar as agremiações',
        onRetry: () => vm.load(forceRefresh: true),
      );
    }

    if (vm.institutions.isEmpty) {
      return KicksterEmptyState(
        icon: Icons.shield_outlined,
        message: 'Nenhuma agremiação cadastrada',
        description: 'Cadastre a primeira agremiação (clube ou universidade).',
        action: canWrite
            ? KicksterButton(
                label: 'Criar agremiação',
                icon: Icons.add,
                onPressed: () => context.go('/institutions/new'),
              )
            : null,
      );
    }

    return AppEntityListScreen<Institution>(
      items: vm.institutions,
      cardBuilder: (inst) => _buildCard(context, inst, vm, canWrite),
      searchField: _searchController,
      emptyMessage: 'Nenhuma agremiação encontrada',
      searchWidth: 220,
      filter: (all, query) {
        if (query != vm.searchQuery) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.setSearchQuery(query);
          });
        }
        return vm.filteredInstitutions;
      },
      toolbarLeading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          SizedBox(
            width: 260,
            child: KicksterDropdown<InstitutionType?>(
              label: 'Filtrar por tipo',
              value: vm.typeFilter,
              values: [null, ...InstitutionType.values],
              labels: [
                'Todas as agremiações',
                ...InstitutionType.values.map((t) => t.label),
              ],
              icons: [
                null,
                ...InstitutionType.values.map(institutionTypeIcon),
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
    Institution inst,
    InstitutionViewModel vm,
    bool canWrite,
  ) {
    final isBusy = vm.actionInProgressId == inst.id;

    return KicksterCard(
      icon: institutionTypeIcon(inst.type),
      title: inst.name,
      subtitle: inst.type.label,
      onTap: () => context.push(
        '/institutions/${inst.id}',
        extra: inst,
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
          // Círculos de cores da agremiação
          if (inst.colors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: inst.colors.take(3).map((hex) {
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: _parseHexColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (canWrite)
            PopupMenuButton<String>(
              tooltip: 'Ações',
              enabled: !isBusy,
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/institutions/${inst.id}/edit', extra: inst);
                } else if (value == 'delete') {
                  final ok = await showKicksterConfirm(
                    context: context,
                    title: 'Excluir agremiação',
                    content: 'Deseja realmente excluir "${inst.name}"?',
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
                                ? '${inst.name} excluída.'
                                : 'Não foi possível excluir a agremiação.',
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Excluir'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
