import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import 'package:flag_admin_web/src/providers/providers.dart';

/// Tela de detalhes de agremiação (camada Views - ADR-001 / MVVM).
class InstitutionDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final Institution? institution;

  const InstitutionDetailScreen({
    super.key,
    required this.id,
    this.institution,
  });

  @override
  ConsumerState<InstitutionDetailScreen> createState() =>
      _InstitutionDetailScreenState();
}

class _InstitutionDetailScreenState
    extends ConsumerState<InstitutionDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.institution == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(institutionDetailViewModelProvider(widget.id)).load();
      });
    }
  }

  Color _parseHexColor(String hex) {
    try {
      return Color(
          int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return AppColors.surfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(institutionDetailViewModelProvider(widget.id));
    final inst = widget.institution ?? vm.institution;
    final orgsAsync = ref.watch(organizationsProvider);

    final instName = inst?.name;
    final breadcrumb = [
      const BreadcrumbItem(AppStrings.home, route: '/'),
      const BreadcrumbItem(AppStrings.institutions, route: '/institutions'),
      if (instName != null) BreadcrumbItem(instName),
    ];

    Widget body;
    if (inst != null) {
      body = AppLayout.detail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ações
            Row(
              children: [
                const Spacer(),
                KicksterButton(
                  label: 'Editar',
                  icon: Icons.edit_outlined,
                  onPressed: () => context.push(
                    '/institutions/${inst.id}/edit',
                    extra: inst,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Card de Identificação
            Card(
              elevation: 1,
              shadowColor: AppColors.black.withValues(alpha: 0.08),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.line, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        institutionTypeIcon(inst.type),
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inst.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tipo: ${inst.type.label}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (inst.colors.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: inst.colors.map((hex) {
                          return Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: _parseHexColor(hex),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Organizações filiadas
            const Text(
              'Organizações Filiadas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            orgsAsync.when(
              data: (orgs) {
                final affiliatedOrgs =
                    orgs.where((o) => inst.organizations.contains(o.id)).toList();
                if (affiliatedOrgs.isEmpty) {
                  return const Text(
                    'Nenhuma organização filiada vinculada.',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: affiliatedOrgs.map((o) {
                    return KicksterBadge(
                      label: o.tradeName,
                      color: AppColors.primary,
                    );
                  }).toList(),
                );
              },
              loading: () => const AppLoading(message: 'Carregando filiações...'),
              error: (e, _) => Text('Erro ao carregar organizações: $e'),
            ),
          ],
        ),
      );
    } else if (vm.isLoading) {
      body = const AppLoading(message: 'Carregando agremiação...');
    } else if (vm.errorMessage != null) {
      body = AppErrorState(
        message: 'Não foi possível carregar a agremiação',
        onRetry: () => vm.load(forceRefresh: true),
      );
    } else {
      body = const SizedBox.shrink();
    }

    return AppScreen(
      title: instName ?? 'Agremiação',
      breadcrumb: breadcrumb,
      body: body,
    );
  }
}
