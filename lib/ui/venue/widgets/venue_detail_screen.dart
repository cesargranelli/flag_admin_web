import 'package:flag_admin_web/domain/models/venue.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/config/providers/providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detalhe de um campo de jogo: apresenta os dados e oferece a edição.
///
/// O campo não possui exclusão (backend sem DELETE). A edição é uma ação
/// explícita na tela.
class VenueDetailScreen extends ConsumerStatefulWidget {
  const VenueDetailScreen({super.key, this.venueId, this.venue});

  final String? venueId;
  final Venue? venue;

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.venueId ?? widget.venue?.id;
      if (id != null && id.isNotEmpty) {
        ref.read(venueDetailViewModelProvider(id)).load(id);
        if (widget.venue != null) {
          ref.read(venueDetailViewModelProvider(id)).setVenue(widget.venue!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.venueId ?? widget.venue?.id ?? '';
    final vm = ref.watch(venueDetailViewModelProvider(id));
    return AppScreen(
      title: vm.venue?.name ?? widget.venue?.name ?? 'Campo',
      breadcrumb: [
        const BreadcrumbItem(AppStrings.home, route: '/'),
        const BreadcrumbItem(AppStrings.venues, route: '/venues'),
        if ((vm.venue?.name ?? widget.venue?.name) != null)
          BreadcrumbItem(vm.venue?.name ?? widget.venue!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: vm,
            builder: (context, _) {
              if (vm.isLoading) {
                return const AppLoading(message: 'Carregando campo...');
              }
              if (vm.errorMessage != null) {
                return AppErrorState(
                  message: vm.errorMessage!,
                  onRetry: () => vm.load(id),
                );
              }
              final venue = vm.venue ?? widget.venue;
              if (venue == null) {
                return const AppErrorState(message: 'Campo não encontrado');
              }
              return _buildDetail(context, venue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Venue venue) {
    // P3 #471: resolve a organização pelo family (autoDispose) em vez de
    // assistir a lista completa.
    //
    // #53: o backend não persiste `organizationId` (campo só para
    // compatibilidade REST de escrita; default '') — com o id
    // vazio, evita disparar um GET /organizations/ sem sentido.
    final orgAsync = venue.organizationId.isEmpty
        ? null
        : ref.watch(organizationProvider(venue.organizationId));
    final orgName = orgAsync?.valueOrNull?.tradeName ?? '';

    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (orgName.isNotEmpty)
                              Text(
                                orgName,
                                style: const TextStyle(
                                  fontSize: 14,
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
                        context.go('/venues/${venue.id}/edit', extra: venue),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppInfoCard(
            children: [
              if (orgName.isNotEmpty)
                AppInfoRow(label: 'Organização', value: orgName),
              AppInfoRow(
                label: 'Endereço',
                value: venue.address?.isNotEmpty == true ? venue.address! : '—',
              ),
              if (venue.mapsUrl != null && venue.mapsUrl!.isNotEmpty)
                AppInfoRow(label: 'URL do mapa', value: venue.mapsUrl!),
            ],
          ),
          if (venue.mapsUrl != null && venue.mapsUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            KicksterButton(
              label: 'Abrir no mapa',
              icon: Icons.map_outlined,
              variant: KicksterButtonVariant.outline,
              onPressed: () => _openMap(context, venue.mapsUrl!),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Criado em ${formatBrDate(venue.createdAt)}'
            '${venue.updatedAt != null ? ' • Atualizado em ${formatBrDate(venue.updatedAt)}' : ''}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap(BuildContext context, String mapsUrl) async {
    final uri = Uri.tryParse(mapsUrl);
    if (uri == null || !(uri.hasScheme && uri.hasAuthority)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o mapa')),
        );
      }
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa')),
      );
    }
  }
}
