import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      body = _buildDetail(context, org);
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
  Widget _buildDetail(BuildContext context, Organization org) {
    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            title: 'Agremiações Filiadas',
            icon: Icons.shield_outlined,
            child: _agremiacoesFiliadasCard(context, org),
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

  /// Seção 5 — Agremiações Filiadas (Clubes e Universidades filiados a esta organização).
  Widget _agremiacoesFiliadasCard(BuildContext context, Organization org) {
    final institutionsAsync = ref.watch(institutionsProvider);

    return institutionsAsync.when(
      data: (institutions) {
        final affiliated = institutions
            .where((inst) => inst.organizations.contains(org.id))
            .toList();

        if (affiliated.isEmpty) {
          return Card(
            elevation: 1,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.line, width: 1),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Nenhuma agremiação filiada a esta organização até o momento.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 2 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 96,
              ),
              itemCount: affiliated.length,
              itemBuilder: (context, index) {
                final inst = affiliated[index];
                final subtitle = [
                  inst.type.label,
                  if (inst.abbreviation != null && inst.abbreviation!.isNotEmpty)
                    inst.abbreviation!,
                  if (inst.city != null && inst.city!.isNotEmpty)
                    inst.city!,
                ].join(' • ');

                return KicksterCard(
                  imageUrl: inst.logoUrl,
                  icon: institutionTypeIcon(inst.type),
                  title: inst.tradeName.isNotEmpty ? inst.tradeName : inst.name,
                  subtitle: subtitle,
                  onTap: () => context.push(
                    '/institutions/${inst.id}',
                    extra: inst,
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const AppLoading(message: 'Carregando agremiações filiadas...'),
      error: (err, _) => Text(
        'Erro ao carregar agremiações filiadas: $err',
        style: const TextStyle(color: AppColors.danger),
      ),
    );
  }
}