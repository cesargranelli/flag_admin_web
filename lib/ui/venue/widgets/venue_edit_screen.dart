import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/domain/models/venue.dart';

/// Tela dedicada EXCLUSIVAMENTE à EDIÇÃO de campo existente (ADR-011 / Kickster Design System).
class VenueEditScreen extends ConsumerStatefulWidget {
  const VenueEditScreen({super.key, required this.venueId, this.venue});

  final String venueId;
  final Venue? venue;

  @override
  ConsumerState<VenueEditScreen> createState() => _VenueEditScreenState();
}

class _VenueEditScreenState extends ConsumerState<VenueEditScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final venue = widget.venue;
      if (venue != null) {
        ref.read(venueEditViewModelProvider(widget.venueId)).init(venue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(venueEditViewModelProvider(widget.venueId));

    return AppScreen(
      title: 'Editar campo',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.venues, route: '/venues'),
        BreadcrumbItem('Editar'),
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

                // Seção: Organização (read-only)
                _buildSectionCard(
                  title: 'Organização',
                  icon: Icons.business_outlined,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final orgId = vm.organizationId;
                      final orgAsync =
                          orgId != null && orgId.isNotEmpty
                              ? ref.watch(organizationProvider(orgId))
                              : null;
                      final orgName =
                          orgAsync?.valueOrNull?.tradeName ?? orgId ?? '—';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          KicksterCard(
                            icon: Icons.business_outlined,
                            title: orgName,
                            subtitle: 'Organização dona do cadastro',
                            onTap: () {},
                          ),
                          const EditRestrictionNote(
                            message:
                                'Organização dona do cadastro não pode ser alterada.',
                            padding: EdgeInsets.only(top: 8),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Seção: Dados do Campo
                _buildSectionCard(
                  title: 'Dados do Campo',
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
                                    content: Text('Campo atualizado com sucesso'),
                                  ),
                                );
                                ref.read(venueListViewModelProvider).load(forceRefresh: true);
                                ref.invalidate(venueDetailViewModelProvider(widget.venueId));
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
