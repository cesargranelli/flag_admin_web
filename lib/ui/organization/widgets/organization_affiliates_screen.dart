import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/domain/models/affiliation.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_affiliates_view_model.dart';

/// Tela dedicada para Consulta e Gestão de Agremiações Filiadas (ADR-001 / MVVM 1:1).
///
/// Suporta grandes volumes de filiados por temporada, com filtros compostos,
/// busca textual e ações operacionais no padrão Kickster.
class OrganizationAffiliatesScreen extends ConsumerStatefulWidget {
  final String organizationId;
  final Organization? organization;

  const OrganizationAffiliatesScreen({
    super.key,
    required this.organizationId,
    this.organization,
  });

  @override
  ConsumerState<OrganizationAffiliatesScreen> createState() =>
      _OrganizationAffiliatesScreenState();
}

class _OrganizationAffiliatesScreenState
    extends ConsumerState<OrganizationAffiliatesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(organizationAffiliatesViewModelProvider(widget.organizationId))
          .load(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(
        organizationAffiliatesViewModelProvider(widget.organizationId));
    final org = vm.organization ?? widget.organization;
    final orgName = org?.tradeName ?? 'Organização';

    final breadcrumb = [
      const BreadcrumbItem(AppStrings.home, route: '/'),
      const BreadcrumbItem(AppStrings.organizations, route: '/organizations'),
      BreadcrumbItem(orgName, route: '/organizations/${widget.organizationId}'),
      const BreadcrumbItem('Agremiações Filiadas'),
    ];

    Widget body;
    if (vm.isLoading && vm.affiliations.isEmpty) {
      body = const AppLoading(message: 'Carregando agremiações filiadas...');
    } else if (vm.errorMessage != null && vm.affiliations.isEmpty) {
      body = AppErrorState(
        message: 'Não foi possível carregar os filiados',
        onRetry: () => vm.load(forceRefresh: true),
      );
    } else {
      body = _buildContent(context, vm, org);
    }

    return AppScreen(
      title: 'Agremiações Filiadas',
      scrollable: false,
      breadcrumb: breadcrumb,
      body: body,
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrganizationAffiliatesViewModel vm,
    Organization? org,
  ) {
    final filtered = vm.filteredAffiliations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Barra Superior de Resumo e Métricas
        _buildMetricsHeader(vm),
        const SizedBox(height: 16),

        // 2. Barra de Filtros Padrão Kickster
        _buildFilters(vm),
        const SizedBox(height: 16),

        // 3. Listagem de Agremiações
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(vm)
              : _buildAffiliatesList(context, vm, filtered),
        ),
      ],
    );
  }

  Widget _buildMetricsHeader(OrganizationAffiliatesViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temporada ${vm.selectedSeason}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vm.approvedCount} filiados ativos • ${vm.pendingCount} solicitações pendentes',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => vm.load(forceRefresh: true),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(OrganizationAffiliatesViewModel vm) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Busca textual
        SizedBox(
          width: 320,
          child: KicksterSearchField(
            controller: _searchController,
            hint: 'Buscar por nome ou responsável...',
            onChanged: vm.setSearchQuery,
          ),
        ),

        // Filtro de Temporada
        SizedBox(
          width: 120,
          child: KicksterDropdown<String>(
            label: '',
            value: vm.selectedSeason,
            values: const ['2026', '2025', '2024'],
            labels: const ['2026', '2025', '2024'],
            onChanged: (v) {
              if (v != null) vm.setSelectedSeason(v);
            },
          ),
        ),

        // Filtro de Status
        SizedBox(
          width: 180,
          child: KicksterDropdown<String?>(
            label: '',
            value: vm.selectedStatus,
            values: const [null, 'APPROVED', 'PENDING', 'REJECTED'],
            labels: const [
              'Todos os status',
              'Filiados (Aprovados)',
              'Pendentes',
              'Recusados',
            ],
            onChanged: vm.setSelectedStatus,
          ),
        ),

        // Filtro de Tipo
        SizedBox(
          width: 160,
          child: KicksterDropdown<String?>(
            label: '',
            value: vm.selectedType,
            values: const [null, 'CLUB', 'UNIVERSITY'],
            labels: const [
              'Todos os tipos',
              'Clubes',
              'Universidades',
            ],
            onChanged: vm.setSelectedType,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(OrganizationAffiliatesViewModel vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma agremiação encontrada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tente ajustar os filtros ou a busca selecionada.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffiliatesList(
    BuildContext context,
    OrganizationAffiliatesViewModel vm,
    List<Affiliation> affiliates,
  ) {
    return ListView.separated(
      itemCount: affiliates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final affil = affiliates[index];

        Color statusColor;
        String statusLabel;
        IconData statusIcon;

        if (affil.isApproved) {
          statusColor = AppColors.success;
          statusLabel = 'Filiado';
          statusIcon = Icons.check_circle_outline;
        } else if (affil.isPending) {
          statusColor = Colors.orange;
          statusLabel = 'Pendente';
          statusIcon = Icons.hourglass_top_outlined;
        } else if (affil.isRejected) {
          statusColor = AppColors.danger;
          statusLabel = 'Recusado';
          statusIcon = Icons.cancel_outlined;
        } else {
          statusColor = AppColors.textSecondary;
          statusLabel = affil.status;
          statusIcon = Icons.info_outline;
        }

        final typeLabel = affil.institutionType == 'UNIVERSITY'
            ? 'Universidade'
            : 'Clube';

        return Card(
          elevation: 1,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                KicksterAvatar(
                  name: affil.institutionName,
                  imageUrl: affil.institutionLogoUrl,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              affil.institutionName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              typeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Temporada ${affil.season} • Solicitado por: ${affil.requestedBy ?? "Responsável"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (affil.rejectionReason != null &&
                          affil.rejectionReason!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Motivo da recusa: ${affil.rejectionReason}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (affil.isPending) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Aprovar filiação',
                    icon: const Icon(Icons.check, color: AppColors.success),
                    onPressed: () async {
                      final ok = await showKicksterConfirm(
                        context: context,
                        title: 'Aprovar Filiação',
                        content:
                            'Deseja aprovar a filiação de "${affil.institutionName}" para a temporada ${affil.season}?',
                        confirmLabel: 'Aprovar',
                      );
                      if (ok == true) {
                        await vm.approveAffiliation(affil.id);
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Recusar filiação',
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: () =>
                        _showRejectAffiliationModal(context, vm, affil),
                  ),
                ],
                const SizedBox(width: 4),
                KicksterMenuAnchor(
                  width: 220,
                  alignment: Alignment.topRight,
                  trigger: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  items: [
                    KicksterMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 18, color: AppColors.primary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ver Detalhes do Clube',
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
                      onTap: () =>
                          context.push('/institutions/${affil.institutionId}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectAffiliationModal(
    BuildContext context,
    OrganizationAffiliatesViewModel vm,
    Affiliation affil,
  ) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Recusar Filiação: ${affil.institutionName}'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Informe o motivo da recusa para que a agremiação possa regularizar suas pendências:',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                KicksterInput(
                  label: 'Motivo da Recusa *',
                  controller: reasonCtrl,
                  maxLines: 3,
                  hintText: 'Ex.: Estatuto desatualizado ou anuidade pendente',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe a justificativa'
                      : null,
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
            label: 'Confirmar Recusa',
            variant: KicksterButtonVariant.outline,
            loading: vm.isReviewing,
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await vm.rejectAffiliation(
                  affil.id, reasonCtrl.text.trim());
              if (ok && dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filiação recusada.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
