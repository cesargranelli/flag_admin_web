import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';

/// Tela dedicada EXCLUSIVAMENTE ao CADASTRO de novo local (ADR-011 / Kickster Design System).
class VenueCreateScreen extends ConsumerStatefulWidget {
  const VenueCreateScreen({super.key});

  @override
  ConsumerState<VenueCreateScreen> createState() => _VenueCreateScreenState();
}

class _VenueCreateScreenState extends ConsumerState<VenueCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(venueCreateViewModelProvider);
    final organizationsAsync = ref.watch(organizationsProvider);

    return AppScreen(
      title: 'Novo local',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.venues, route: '/venues'),
        BreadcrumbItem('Novo'),
      ],
      body: AppLayout.form(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (vm.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Seção: Organização
                _buildSectionCard(
                  title: 'Organização',
                  icon: Icons.business_outlined,
                  child: organizationsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => AppErrorState(
                      message: 'Erro ao carregar organizações',
                      onRetry: () => ref.invalidate(organizationsProvider),
                    ),
                    data: (orgs) {
                      if (orgs.isEmpty) {
                        return const AppEmptyState(
                          message: 'Cadastre uma organização antes de criar locais',
                          icon: Icons.business,
                        );
                      }
                      return KicksterDropdown<String>(
                        label: 'Organização',
                        value: vm.organizationId,
                        hint: 'Selecione a Organização',
                        items: orgs
                            .map(
                              (o) => DropdownMenuItem(
                                value: o.id,
                                child: Text(o.tradeName),
                              ),
                            )
                            .toList(),
                        onChanged: vm.setOrganizationId,
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? 'Selecione a organização'
                                : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Seção: Dados do Local
                _buildSectionCard(
                  title: 'Dados do Local',
                  icon: Icons.sports_soccer_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KicksterInput(
                        label: 'Nome',
                        controller: vm.nameController,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe o nome'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      KicksterInput(
                        label: 'Endereço',
                        controller: vm.addressController,
                      ),
                      const SizedBox(height: 12),
                      KicksterInput(
                        label: 'URL do mapa',
                        controller: vm.mapsUrlController,
                        keyboardType: TextInputType.url,
                        hintText: 'Ex.: https://maps.app.goo.gl/...',
                        validator: _validateMapsUrl,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    KicksterButton(
                      label: 'Cancelar',
                      variant: KicksterButtonVariant.outline,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    KicksterButton(
                      label: 'Salvar',
                      icon: Icons.check,
                      loading: vm.isSubmitting,
                      onPressed: vm.isSubmitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final result = await vm.save();
if (result && context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(
                                     content: Text('Local criado com sucesso'),
                                   ),
                                 );
                                 ref.invalidate(venueListViewModelProvider);
                                 ref.read(venueListViewModelProvider).load(forceRefresh: true);
                                 context.pop();
                               }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(title: title, icon: icon),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line, width: 1),
          ),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );
  }

  String? _validateMapsUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final valid =
        uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
    return valid ? null : 'Informe uma URL válida (http/https)';
  }
}
