import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/date_formats.dart';
import '../widgets/app_screen.dart';

/// Detalhe de um time (#12): apresenta os dados da entidade e oferece a
/// edição.
///
/// O time pertence a uma organização (clube/universidade). A seção de
/// elencos por competição ficará aqui quando o backend suportar.
class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamFuture = team != null ? null : ref.watch(teamProvider(teamId!));

    return AppScreen(
      title: team?.name ?? 'Time',
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.teams, route: '/teams'),
        if (team?.name != null) BreadcrumbItem(team!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          teamFuture == null
              ? _buildDetail(context, ref, team!)
              : teamFuture.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando time...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar o time',
                    onRetry: () => ref.invalidate(teamProvider(teamId!)),
                  ),
                  data: (team) => _buildDetail(context, ref, team),
                ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Team team) {
    // Resolve o nome do clube/universidade dono do time quando a lista de
    // organizações já carregou (fallback: id bruto).
    final orgs =
        ref.watch(organizationsProvider).valueOrNull ?? const <Organization>[];
    final orgName = orgs
        .where((o) => o.id == team.organizationId)
        .map((o) => o.tradeName)
        .firstOrNull;

    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card (estilo KicksterCard): logo/avatar + nome + clube.
          Card(
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
                      _avatar(team, size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            if (team.shortName?.isNotEmpty ?? false)
                              Text(
                                team.shortName!,
                                style: AppTextStyles.paragraph.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Clube: ${orgName ?? team.organizationId}',
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
                  KicksterButton(
                    label: 'Editar dados',
                    icon: Icons.edit_outlined,
                    onPressed: () =>
                        context.go('/teams/${team.id}/edit', extra: team),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Informações do time.
          AppInfoCard(
            children: [
              AppInfoRow(label: 'Nome', value: team.name),
              AppInfoRow(
                label: 'Sigla',
                value:
                    team.shortName?.isNotEmpty == true ? team.shortName! : '—',
              ),
              AppInfoRow(
                label: 'Esporte',
                value:
                    team.sportName?.isNotEmpty == true ? team.sportName! : '—',
              ),
              AppInfoRow(
                label: 'URL do logo',
                value: team.logoUrl?.isNotEmpty == true ? team.logoUrl! : '—',
              ),
              AppInfoRow(
                label: 'Status',
                value: team.status?.isNotEmpty == true ? team.status! : '—',
              ),
              AppInfoRow(label: 'Criado em', value: formatBrDate(team.createdAt)),
              AppInfoRow(
                label: 'Atualizado em',
                value: formatBrDate(team.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Elencos por competição (futuro): o backend ainda não expõe os
          // elencos por competição — apenas a nota informativa (#12).
          const KicksterSectionTitle(
            title: 'Elencos',
            icon: Icons.groups_outlined,
          ),
          const SizedBox(height: 12),
          const AppInfoCard(
            children: [
              Text(
                'Elencos por competição estarão disponíveis em breve.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Avatar do time: logo (Image.network) quando a URL é válida, ou o ícone
  /// de grupos como fallback.
  Widget _avatar(Team team, {required double size}) {
    final logo = team.logoUrl;
    final validLogo =
        logo != null &&
        logo.isNotEmpty &&
        (Uri.tryParse(logo)?.hasScheme ?? false);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: validLogo
          ? Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.groups_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            )
          : const Icon(
              Icons.groups_outlined,
              color: AppColors.primary,
              size: 32,
            ),
    );
  }
}