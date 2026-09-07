import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import '../view_models/institution_view_model.dart';

/// Screen principal de Agremiações (camada Views - ADR-001 / MVVM).
///
/// Consome [InstitutionViewModel] e apresenta listagem com busca, filtro por tipo e layout Kickster.
class InstitutionListScreen extends ConsumerStatefulWidget {
  const InstitutionListScreen({super.key});

  @override
  ConsumerState<InstitutionListScreen> createState() => _InstitutionListScreenState();
}

class _InstitutionListScreenState extends ConsumerState<InstitutionListScreen> {
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
                      label: 'Nova Agremiação',
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
        const SizedBox(height: 12),
        Expanded(
          child: vm.filteredInstitutions.isEmpty
              ? _buildEmptyState(vm)
              : _buildList(context, vm, canWrite),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, InstitutionViewModel vm) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nome...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: vm.setSearchQuery,
              ),
            ),
            const VerticalDivider(width: 24),
            DropdownButton<InstitutionType?>(
              value: vm.typeFilter,
              underline: const SizedBox.shrink(),
              hint: const Text('Todos os tipos'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos os tipos'),
                ),
                ...InstitutionType.values.map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  ),
                ),
              ],
              onChanged: vm.setTypeFilter,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(InstitutionViewModel vm) {
    final hasFilters =
        vm.searchQuery.isNotEmpty || vm.typeFilter != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 56, color: AppColors.textSecondary),
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

  Widget _buildList(
    BuildContext context,
    InstitutionViewModel vm,
    bool canWrite,
  ) {
    final list = vm.filteredInstitutions;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final inst = list[index];
        return _buildCard(context, inst, vm, canWrite);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    Institution inst,
    InstitutionViewModel vm,
    bool canWrite,
  ) {
    final isBusy = vm.actionInProgressId == inst.id;

    // Cores para os swatches (combina 4 cores individuais ou array legados)
    final displayColors = <String>[];
    if (inst.primaryColor != null) displayColors.add(inst.primaryColor!);
    if (inst.secondaryColor != null) displayColors.add(inst.secondaryColor!);
    if (inst.tertiaryColor != null) displayColors.add(inst.tertiaryColor!);
    if (inst.quaternaryColor != null) displayColors.add(inst.quaternaryColor!);
    if (displayColors.isEmpty && inst.colors.isNotEmpty) {
      displayColors.addAll(inst.colors.take(4));
    }

    final subtitle = inst.abbreviation != null && inst.abbreviation!.isNotEmpty
        ? '${inst.type.label} • ${inst.abbreviation}'
        : inst.type.label;

    return KicksterCard(
      icon: institutionTypeIcon(inst.type),
      imageUrl: inst.logoUrl,
      title: inst.tradeName.isNotEmpty ? inst.tradeName : inst.name,
      subtitle: subtitle,
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
          if (displayColors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: displayColors.map((hex) {
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: _parseHexColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
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
                    content: 'Deseja realmente excluir "${inst.tradeName.isNotEmpty ? inst.tradeName : inst.name}"?',
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
                          backgroundColor:
                              success ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
