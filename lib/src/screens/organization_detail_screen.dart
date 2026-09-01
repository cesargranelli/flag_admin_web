import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/date_formats.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';
import '../widgets/associate_club_modal.dart';

/// Escopo de mutação das desassociações de clube na tela de detalhe.
const _disassociateScope = 'org-club-disassociate';

/// Detalhe de uma organização em página única (#455): todas as seções
/// (identificação, presidente, contato, localização, identidade) empilhadas
/// com títulos de seção — o scroll é do body, sem barras internas.
///
/// A edição é uma ação explícita na tela (organizações não são editáveis
/// após a criação — V250).
class OrganizationDetailScreen extends ConsumerWidget {
  const OrganizationDetailScreen({
    super.key,
    this.organizationId,
    this.organization,
  });

  final String? organizationId;
  final Organization? organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = organization;
    final orgFuture =
        org != null ? null : ref.watch(organizationProvider(organizationId!));

    // Breadcrumb dinâmico com nome da organização
    final orgName = org?.tradeName;
    final breadcrumb = [
      const BreadcrumbItem('Início', route: '/'),
      const BreadcrumbItem(AppStrings.organizations, route: '/organizations'),
      if (orgName != null) BreadcrumbItem(orgName),
    ];

    return AppScreen(
      title: org?.tradeName ?? 'Organização',
      breadcrumb: breadcrumb,
      body: orgFuture == null
          ? _buildDetail(context, ref, org!)
          : orgFuture.when(
              loading: () => const AppLoading(
                message: 'Carregando organização...',
              ),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar a organização',
                onRetry: () => ref.invalidate(
                  organizationProvider(organizationId!),
                ),
              ),
              data: (org) => _buildDetail(context, ref, org),
            ),
    );
  }

  /// Página única: seções empilhadas, scroll do body (#455).
  Widget _buildDetail(BuildContext context, WidgetRef ref, Organization org) {
    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(
            title: 'Identificação',
            icon: Icons.business_outlined,
            child: _identificacaoCard(context, org),
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
            title: 'Identidade',
            icon: Icons.palette_outlined,
            child: _identidadeCard(org),
          ),
          // A seção de entidades depende do tipo da organização:
          // - Clube/Universidade → Times (listar/criar times do clube)
          // - Federação/Liga/Associação → Clubes (associar organizações filhas)
          if (_isClubLike(org))
            _section(
              title: 'Times',
              icon: Icons.groups_outlined,
              child: _timesCard(context, ref, org),
            )
          else
            _section(
              title: 'Clubes',
              icon: Icons.groups_outlined,
              child: _clubesCard(context, ref, org),
            ),
        ],
      ),
    );
  }

  /// Organização do tipo Clube/Universidade (tem Times).
  bool _isClubLike(Organization org) =>
      org.organizationType == OrganizationType.club ||
      org.organizationType == OrganizationType.university;

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

  /// Seção 1 — Identificação (#323): card hero consolidado + dados.
  /// Estilo KicksterCard: elevation 1, shadow, border line, borderRadius 12.
  Widget _identificacaoCard(BuildContext context, Organization org) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    organizationTypeIcon(org.organizationType),
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.tradeName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        org.legalName,
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (org.abbreviation != null && org.abbreviation!.isNotEmpty)
              AppInfoRow(label: 'Sigla', value: org.abbreviation!),
            if (org.organizationType != null)
              AppInfoRow(label: 'Tipo', value: org.organizationType!.label),
            if (org.document != null && org.document!.isNotEmpty)
              AppInfoRow(label: 'CNPJ', value: org.document!),
            if (org.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Criada em ${formatBrDate(org.createdAt!)}',
                style: AppTextStyles.fieldLabel.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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

  /// Seção 5 — Identidade (#323): renomeado de 'Visual'.
  Widget _identidadeCard(Organization org) {
    return AppInfoCard(
      children: [
        if (org.locale.isNotEmpty) AppInfoRow(label: 'Locale', value: org.locale),
        if (org.primaryColor != null && org.primaryColor!.isNotEmpty)
          AppInfoColorRow(label: 'Cor primária', hex: org.primaryColor!),
        if (org.secondaryColor != null && org.secondaryColor!.isNotEmpty)
          AppInfoColorRow(label: 'Cor secundária', hex: org.secondaryColor!),
        if (org.tertiaryColor != null && org.tertiaryColor!.isNotEmpty)
          AppInfoColorRow(label: 'Cor terciária', hex: org.tertiaryColor!),
        if (org.quaternaryColor != null && org.quaternaryColor!.isNotEmpty)
          AppInfoColorRow(label: 'Cor quaternária', hex: org.quaternaryColor!),
        if (org.logoUrl != null && org.logoUrl!.isNotEmpty)
          AppInfoRow(label: 'Logo', value: org.logoUrl!),
      ],
    );
  }

  /// Seção 6 — Clubes (#12/#497): lista apenas os clubes/universidades
  /// ASSOCIADOS à federação/liga/associação + botão para associar novos.
  ///
  /// Consome `GET /api/v1/organizations/{id}/clubs` (hierarquia ADR-006).
  Widget _clubesCard(BuildContext context, WidgetRef ref, Organization org) {
    final associatedAsync = ref.watch(associatedClubsProvider(org.id));
    final canEdit = ref
            .watch(authControllerProvider.select((a) => a.state.user?.role)) ==
        UserRole.admin;

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: KicksterButton(
                label: 'Associar clube',
                icon: Icons.add,
                onPressed: canEdit
                    ? () => showAssociateClubModal(
                          context,
                          organizationId: org.id,
                        )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            associatedAsync.when(
              loading: () => const Text(
                'Carregando clubes...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              error: (e, s) => const Text(
                'Não foi possível carregar os clubes.',
                style: TextStyle(fontSize: 13, color: AppColors.danger),
              ),
              data: (clubs) {
                if (clubs.isEmpty) {
                  return const Text(
                    'Nenhum clube associado. Associe clubes ou '
                    'universidades a esta organização.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < clubs.length; i++) ...[
                      _clubCard(context, ref, clubs[i], org.id),
                      if (i != clubs.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Card de clube/universidade associado no padrão Kickster (#12): ícone do
  /// tipo, nome fantasia + cidade, clique → detalhe do clube, e ícone de
  /// desassociação (quando ADMIN).
  Widget _clubCard(
    BuildContext context,
    WidgetRef ref,
    Organization club,
    String orgId,
  ) {
    final disassociating =
        ref.watch(mutationProgressProvider(_disassociateScope)).contains(club.id);

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(
          '/organizations/${club.id}',
          extra: club,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  organizationTypeIcon(club.organizationType),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.tradeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (club.city?.isNotEmpty ?? false)
                      Text(
                        club.city!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (disassociating)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Desassociar',
                  icon: const Icon(
                    Icons.link_off,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  onPressed: () => _disassociateClub(context, ref, club, orgId),
                ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Remove a associação do clube à organização (zera o parentId).
  Future<void> _disassociateClub(
    BuildContext context,
    WidgetRef ref,
    Organization club,
    String orgId,
  ) async {
    await runMutation(
      context,
      ref: ref,
      scope: _disassociateScope,
      action: () =>
          ref.read(organizationApiProvider).disassociateClub(orgId, club.id),
      successMessage: '${club.tradeName} desassociado da organização.',
      errorMessage: 'Não foi possível desassociar o clube.',
      progressId: club.id,
      onSuccess: () {
        ref.invalidate(associatedClubsProvider(orgId));
        ref.invalidate(organizationsProvider);
      },
    );
  }

  /// Seção 6 — Times (#12): criação e listagem dos times do clube.
  ///
  /// O time pertence à organização, então o "Novo time" navega para
  /// `/teams/new` com o `organizationId` no extra (rota corrigida — antes
  /// o botão vivia na tela de times por competição e enviava o id errado).
  Widget _timesCard(BuildContext context, WidgetRef ref, Organization org) {
    final teamsAsync = ref.watch(clubTeamsProvider(org.id));

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: KicksterButton(
                label: 'Novo time',
                icon: Icons.add,
                onPressed: () => context.go('/teams/new', extra: org.id),
              ),
            ),
            const SizedBox(height: 16),
            teamsAsync.when(
              loading: () => const Text(
                'Carregando times...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              error: (e, s) => const Text(
                'Não foi possível carregar os times.',
                style: TextStyle(fontSize: 13, color: AppColors.danger),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return const Text(
                    'Nenhum time cadastrado. Crie o primeiro time do clube.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < teams.length; i++) ...[
                      _teamCard(context, teams[i]),
                      if (i != teams.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Card de time no padrão Kickster (#12): ícone de grupo, nome e sigla.
  Widget _teamCard(BuildContext context, Team team) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go('/teams/${team.id}', extra: team),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (team.shortName?.isNotEmpty ?? false)
                      Text(
                        team.shortName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}