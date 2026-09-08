import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_detail_view_model.dart';

import 'package:flag_admin_web/src/providers/providers.dart';

/// Detalhe de uma organização em página única (#455): todas as seções
/// (identificação, presidente, contato, localização, identidade) empilhadas
/// com títulos de seção — o scroll é do body, sem barras internas.
///
/// A edição é uma ação explícita na tela (organizações não são editáveis
/// após a criação — V250).
class OrganizationDetailScreen extends ConsumerStatefulWidget {
  const OrganizationDetailScreen({
    super.key,
    this.organizationId,
    this.organization,
  });

  final String? organizationId;
  final Organization? organization;

  @override
  ConsumerState<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState
    extends ConsumerState<OrganizationDetailScreen> {
  @override
  void initState() {
    super.initState();
    final id = widget.organizationId ?? widget.organization?.id;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(organizationDetailViewModelProvider(id)).load(forceRefresh: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.organizationId ?? widget.organization?.id ?? '';
    final vm = ref.watch(organizationDetailViewModelProvider(id));
    final org = vm.organization ?? widget.organization;

    // Breadcrumb dinâmico com nome da organização
    final orgName = org?.tradeName;
    final breadcrumb = [
      const BreadcrumbItem(AppStrings.home, route: '/'),
      const BreadcrumbItem(AppStrings.organizations, route: '/organizations'),
      if (orgName != null) BreadcrumbItem(orgName),
    ];

    Widget body;
    if (org != null) {
      body = _buildDetail(context, org, vm);
    } else if (vm.isLoading) {
      body = const AppLoading(
        message: 'Carregando organização...',
      );
    } else if (vm.errorMessage != null) {
      body = AppErrorState(
        message: 'Não foi possível carregar a organização',
        onRetry: () => vm.load(forceRefresh: true),
      );
    } else {
      body = const SizedBox.shrink();
    }

    return AppScreen(
      title: org?.tradeName ?? 'Organização',
      breadcrumb: breadcrumb,
      body: body,
    );
  }

  /// Página única: seções empilhadas, scroll do body (#455).
  Widget _buildDetail(
    BuildContext context,
    Organization org,
    OrganizationDetailViewModel vm,
  ) {
    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ações superiores
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () async {
                  await context.push(
                    '/organizations/${org.id}/edit',
                    extra: org,
                  );
                  if (context.mounted) {
                    ref
                        .read(organizationDetailViewModelProvider(org.id))
                        .load(forceRefresh: true);
                    ref
                        .read(organizationViewModelProvider)
                        .load(forceRefresh: true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            title: 'Identificação',
            icon: Icons.business_outlined,
            child: _identificacaoCard(org),
          ),
          _section(
            title: 'Presidente',
            icon: Icons.person_outline,
            child: _presidenteCard(org),
          ),
          _section(
            title: 'Contato',
            icon: Icons.contact_mail_outlined,
            child: _contatoCard(org),
          ),
          _section(
            title: 'Localização',
            icon: Icons.location_on_outlined,
            child: _localizacaoCard(org),
          ),
          _section(
            title: 'Agremiações Filiadas & Pedidos de Filiação',
            icon: Icons.shield_outlined,
            child: _agremiacoesFiliadasCard(context, org, vm),
          ),
        ],
      ),
    );
  }

  /// Título de seção (titleMedium) + card, separados por espaçamento padrão.
  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(title: title, icon: icon),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  Color? _parseHex(String? text) {
    if (text == null) return null;
    var raw = text.trim();
    if (raw.isEmpty) return null;
    if (!raw.startsWith('#')) raw = '#$raw';
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(raw)) return null;
    try {
      return Color(int.parse('0xFF${raw.substring(1)}'));
    } catch (_) {
      return null;
    }
  }

  Widget _buildLogoFallback(Organization org, Color primary) {
    final initials = org.abbreviation?.isNotEmpty == true
        ? org.abbreviation!.toUpperCase()
        : (org.tradeName.isNotEmpty ? org.tradeName.substring(0, 1).toUpperCase() : 'O');
    return Container(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: primary,
          ),
        ),
      ),
    );
  }

  /// Seção 1 — Identificação (#323 / #93): Card Hero Esportivo Kickster com cores e logo real.
  Widget _identificacaoCard(Organization org) {
    final primary = _parseHex(org.primaryColor) ?? AppColors.primary;
    final secondary = _parseHex(org.secondaryColor) ?? const Color(0xFF1877F2);
    final tertiary = _parseHex(org.tertiaryColor);
    final quaternary = _parseHex(org.quaternaryColor);

    final isLightPrimary = primary.computeLuminance() > 0.55;
    final bannerTextColor = isLightPrimary ? AppColors.black : Colors.white;

    return Card(
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Superior com Gradiente das Cores da Organizacao
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  Color.lerp(primary, secondary, 0.5) ?? secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador de Cores Oficiais
                Row(
                  children: [
                    _buildSwatchBadge(primary, 'Cor primária'),
                    const SizedBox(width: 6),
                    _buildSwatchBadge(secondary, 'Cor secundária'),
                    if (tertiary != null) ...[
                      const SizedBox(width: 6),
                      _buildSwatchBadge(tertiary, 'Cor terciária'),
                    ],
                    if (quaternary != null) ...[
                      const SizedBox(width: 6),
                      _buildSwatchBadge(quaternary, 'Cor quaternária'),
                    ],
                  ],
                ),
                // Sigla Oficial no Banner
                if (org.abbreviation != null && org.abbreviation!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bannerTextColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: bannerTextColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      org.abbreviation!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: bannerTextColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Area de Identidade com Avatar Hero de 88px e Dados
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Hero de 88px ampliado com borda e sombra
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: org.logoUrl != null && org.logoUrl!.trim().isNotEmpty
                            ? Image.network(
                                org.logoUrl!.trim(),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildLogoFallback(org, primary),
                              )
                            : _buildLogoFallback(org, primary),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Titulos e Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org.tradeName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            org.legalName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (org.organizationType != null)
                                Chip(
                                  avatar: Icon(
                                    organizationTypeIcon(org.organizationType),
                                    size: 16,
                                    color: primary,
                                  ),
                                  label: Text(
                                    org.organizationType!.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: primary.withValues(alpha: 0.08),
                                  side: BorderSide(color: primary.withValues(alpha: 0.2)),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (org.country.isNotEmpty)
                                Chip(
                                  avatar: const Icon(
                                    Icons.flag_outlined,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  label: Text(
                                    org.country,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: AppColors.surfaceMuted,
                                  side: const BorderSide(color: AppColors.line),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.line, height: 1),
                const SizedBox(height: 16),

                // Detalhes Cadastrais
                if (org.abbreviation != null && org.abbreviation!.isNotEmpty)
                  AppInfoRow(label: 'Sigla Oficial', value: org.abbreviation!),
                if (org.document != null && org.document!.isNotEmpty)
                  AppInfoRow(label: 'CNPJ', value: org.document!),
                if (org.locale.isNotEmpty)
                  AppInfoRow(label: 'Idioma', value: org.locale),
                if (org.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Cadastrada em ${formatBrDate(org.createdAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwatchBadge(Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// Seção 2 — Presidente (#323).
  Widget _presidenteCard(Organization org) {
    return AppInfoCard(
      children: [
        if (org.presidentName != null && org.presidentName!.isNotEmpty)
          AppInfoRow(label: 'Nome', value: org.presidentName!),
        if (org.presidentCpf != null && org.presidentCpf!.isNotEmpty)
          AppInfoRow(label: 'CPF', value: org.presidentCpf!),
      ],
    );
  }

  /// Seção 3 — Contato (#323).
  Widget _contatoCard(Organization org) {
    return AppInfoCard(
      children: [
        if (org.email != null && org.email!.isNotEmpty)
          AppInfoRow(label: 'E-mail', value: org.email!),
        if (org.phone != null && org.phone!.isNotEmpty)
          AppInfoRow(label: 'Telefone', value: org.phone!),
        if (org.website != null && org.website!.isNotEmpty)
          AppInfoRow(label: 'Site', value: org.website!),
        if (org.instagram != null && org.instagram!.isNotEmpty)
          AppInfoRow(label: 'Instagram', value: org.instagram!),
      ],
    );
  }

  /// Seção 4 — Localização (#323): movida de Identificação.
  Widget _localizacaoCard(Organization org) {
    return AppInfoCard(
      children: [
        AppInfoRow(label: 'País', value: org.country),
        if (org.state != null && org.state!.isNotEmpty)
          AppInfoRow(label: 'Estado', value: org.state!),
        if (org.city != null && org.city!.isNotEmpty)
          AppInfoRow(label: 'Cidade', value: org.city!),
      ],
    );
  }

  /// Seção 5 — Cockpit de Agremiações Filiadas & Pedidos de Filiação (ADR-001 / MVVM).
  Widget _agremiacoesFiliadasCard(
    BuildContext context,
    Organization org,
    OrganizationDetailViewModel vm,
  ) {
    final pendingAffiliations = vm.affiliations.where((a) => a.isPending).toList();
    final approvedAffiliations = vm.affiliations.where((a) => a.isApproved).toList();

    return Card(
      elevation: 1,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Linha Superior: Temporada e Métricas Rápidas
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${approvedAffiliations.length} Filiados Ativos',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (pendingAffiliations.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${pendingAffiliations.length} Pendentes',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.line),
            const SizedBox(height: 16),

            // 1.1 Status e Controle do Período de Inscrições da Temporada
            Builder(builder: (ctx) {
              final win = vm.currentWindow;
              final isOpen = win?.isOpen ?? false;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isOpen
                      ? AppColors.success.withValues(alpha: 0.06)
                      : AppColors.surfaceMuted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOpen
                        ? AppColors.success.withValues(alpha: 0.25)
                        : AppColors.line,
                  ),
                ),
                child: Row(
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
                                ? 'Inscrições Abertas (Temporada ${vm.selectedSeason})'
                                : 'Inscrições Encerradas / Fechadas',
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
                    if (isOpen)
                      KicksterButton(
                        label: 'Encerrar Inscrições',
                        variant: KicksterButtonVariant.outline,
                        loading: vm.isSavingWindow,
                        onPressed: () async {
                          final ok = await showKicksterConfirm(
                            context: context,
                            title: 'Encerrar Inscrições',
                            content: 'Deseja encerrar o período de filiações para a temporada ${vm.selectedSeason}?',
                            confirmLabel: 'Encerrar',
                            danger: true,
                          );
                          if (ok == true) {
                            await vm.closeAffiliationWindow(vm.selectedSeason);
                          }
                        },
                      )
                    else
                      KicksterButton(
                        label: 'Abrir Período',
                        icon: Icons.add,
                        variant: KicksterButtonVariant.outline,
                        onPressed: () => _showOpenWindowModal(context, vm),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Divider(color: AppColors.line),
            const SizedBox(height: 16),

            // 2. Inbox de Triagem Imediata de Solicitações Pendentes
            if (vm.isLoadingAffiliations)
              const Center(child: AppLoading(message: 'Carregando filiações...'))
            else if (pendingAffiliations.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.hourglass_top_outlined, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Solicitações Aguardando Aprovação (${pendingAffiliations.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingAffiliations.length,
                separatorBuilder: (_, _) => const Divider(color: AppColors.line, height: 18),
                itemBuilder: (context, index) {
                  final affil = pendingAffiliations[index];
                  return Row(
                    children: [
                      KicksterAvatar(
                        name: affil.institutionName,
                        imageUrl: affil.institutionLogoUrl,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              affil.institutionName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tipo: ${affil.institutionType == "UNIVERSITY" ? "Universidade" : "Clube"} • Resp: ${affil.requestedBy ?? "Responsável"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Aprovar filiação',
                        icon: const Icon(Icons.check, color: AppColors.success),
                        onPressed: () async {
                          final ok = await showKicksterConfirm(
                            context: context,
                            title: 'Aprovar Filiação',
                            content: 'Deseja aprovar a filiação de "${affil.institutionName}" para a temporada ${affil.season}?',
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
                        onPressed: () => _showRejectAffiliationModal(context, vm, affil),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.line),
              const SizedBox(height: 16),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                    SizedBox(width: 8),
                    Text(
                      'Nenhuma solicitação pendente no momento.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 3. Botão de Acesso ao Quadro Geral de Afiliados
            KicksterButton(
              label: 'Ver Quadro Geral de Afiliados (${approvedAffiliations.length})',
              icon: Icons.people_outline,
              variant: KicksterButtonVariant.outline,
              onPressed: () => context.push(
                '/organizations/${org.id}/affiliates',
                extra: org,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenWindowModal(
    BuildContext context,
    OrganizationDetailViewModel vm,
  ) {
    final seasonCtrl = TextEditingController(text: vm.selectedSeason);
    final titleCtrl = TextEditingController(text: 'Filiações ${vm.selectedSeason}');
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
            title: const Text('Abrir Período de Inscrição de Filiações'),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Defina o prazo durante o qual clubes e universidades poderão solicitar filiação à organização.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: KicksterInput(
                            label: 'Temporada (Ano) *',
                            controller: seasonCtrl,
                            hintText: 'Ex: 2026',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: KicksterInput(
                            label: 'Título do Período *',
                            controller: titleCtrl,
                            hintText: 'Ex: Filiações 2026',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                          ),
                        ),
                      ],
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
                                  final picked = await showDatePicker(
                                    context: context,
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
                                  final picked = await showDatePicker(
                                    context: context,
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
                      hintText: 'Ex: Anexar ata de posse da diretoria e comprovante de taxa.',
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
                  final ok = await vm.openAffiliationWindow(
                    season: seasonCtrl.text.trim(),
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

  void _showRejectAffiliationModal(
    BuildContext context,
    OrganizationDetailViewModel vm,
    dynamic affil,
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
                  'Informe o motivo da recusa para que a agremiação possa corrigir eventuais pendências:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                KicksterInput(
                  label: 'Motivo da Recusa *',
                  controller: reasonCtrl,
                  maxLines: 3,
                  hintText: 'Ex.: Estatuto desatualizado ou anuidade pendente',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a justificativa' : null,
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
            loading: vm.isReviewingAffiliation,
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await vm.rejectAffiliation(affil.id, reasonCtrl.text.trim());
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