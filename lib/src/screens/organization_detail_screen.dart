import 'package:flag_admin_web/src/api/flag_api.dart';
import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/core/widgets/image_upload_field.dart';
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

    // Organização resolvida (extra da rota ou provider já carregado).
    final resolvedOrg = org ?? orgFuture?.valueOrNull;

    return AppScreen(
      title: resolvedOrg?.tradeName ?? 'Organização',
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
            child: _identificacaoCard(context, ref, org),
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
  Widget _identificacaoCard(BuildContext context, WidgetRef ref, Organization org) {
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
                // Logo com badge de edição (ou placeholder com ícone do tipo).
                _buildLogoAvatar(context, ref, org),
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
              loading: () => const AppLoading(
                message: 'Carregando clubes...',
              ),
              error: (e, s) => AppErrorState(
                message: 'Não foi possível carregar os clubes.',
                onRetry: () => ref.invalidate(associatedClubsProvider(org.id)),
              ),
              data: (clubs) {
                if (clubs.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.groups_outlined,
                    message: 'Nenhum clube associado',
                    description:
                        'Associe clubes ou universidades a esta organização.',
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

  // ── Logo editing ──────────────────────────────────────────────────────

  /// Avatar circular do logo da organização com badge de edição sobreposto.
  /// Se não houver logo, exibe o ícone do tipo como placeholder.
  Widget _buildLogoAvatar(BuildContext context, WidgetRef ref, Organization org) {
    final hasLogo = org.logoUrl != null && org.logoUrl!.isNotEmpty;

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar circular: logo ou placeholder.
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: hasLogo
                  ? Image.network(
                      org.logoUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _typeIconPlaceholder(org),
                    )
                  : _typeIconPlaceholder(org),
            ),
          ),
          // Badge de edição.
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showLogoEditDialog(context, ref, org),
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeIconPlaceholder(Organization org) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        organizationTypeIcon(org.organizationType),
        color: AppColors.primary,
        size: 32,
      ),
    );
  }

  /// Abre o dialog de edição de logo da organização.
  void _showLogoEditDialog(
    BuildContext context,
    WidgetRef ref,
    Organization org,
  ) {
    var tempLogoUrl = org.logoUrl;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => kicksterModalDialog(
          title: const Text('Trocar logo'),
          content: SizedBox(
            width: 296,
            child: ImageUploadField(
              label: 'Logo da organização',
              apiClient: ref.read(apiClientProvider),
              imageUrl: tempLogoUrl,
              onUrlChanged: (url) {
                setDialogState(() => tempLogoUrl = url);
              },
            ),
          ),
          actions: [
            KicksterButton(
              label: 'Cancelar',
              variant: KicksterButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            KicksterButton(
              label: 'Salvar',
              onPressed: () =>
                  _updateLogo(dialogContext, ref, org, tempLogoUrl),
            ),
          ],
        ),
      ),
    );
  }

  /// Atualiza apenas o logo da organização (mantém todos os outros campos).
  Future<void> _updateLogo(
    BuildContext dialogContext,
    WidgetRef ref,
    Organization org,
    String? newLogoUrl,
  ) async {
    try {
      final api = ref.read(organizationApiProvider);
      final body = org.toJson();
      if (newLogoUrl != null && newLogoUrl.isNotEmpty) {
        body['logoUrl'] = newLogoUrl;
      } else {
        body['logoUrl'] = null;
      }
      await api.update(org.id, body);
      ref.invalidate(organizationProvider(org.id));
      ref.invalidate(organizationsProvider);
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(content: Text('Logo atualizado com sucesso')),
        );
      }
    } on RepositoryException catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar logo: ${e.message}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (_) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o logo.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
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

    return KicksterCard(
      icon: organizationTypeIcon(club.organizationType),
      title: club.tradeName,
      subtitle: (club.city?.isNotEmpty ?? false) ? club.city : null,
      onTap: () => context.push(
        '/organizations/${club.id}',
        extra: club,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                onPressed: () => context.push('/teams/new', extra: org.id),
              ),
            ),
            const SizedBox(height: 16),
            teamsAsync.when(
              loading: () => const AppLoading(
                message: 'Carregando times...',
              ),
              error: (e, s) => AppErrorState(
                message: 'Não foi possível carregar os times.',
                onRetry: () => ref.invalidate(clubTeamsProvider(org.id)),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.groups_outlined,
                    message: 'Nenhum time cadastrado',
                    description: 'Crie o primeiro time do clube.',
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
    return KicksterCard(
      icon: Icons.groups_outlined,
      title: team.name,
      subtitle: (team.shortName?.isNotEmpty ?? false) ? team.shortName : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: () => context.push('/teams/${team.id}', extra: team),
    );
  }
}
