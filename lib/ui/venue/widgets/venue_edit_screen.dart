import 'package:flag_admin_web/domain/models/venue.dart';
import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/ui/venue/view_models/venue_edit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulário de edição de campo de jogo.
class VenueEditScreen extends ConsumerStatefulWidget {
  const VenueEditScreen({super.key, required this.venueId, this.venue});

  final String venueId;
  final Venue? venue;

  @override
  ConsumerState<VenueEditScreen> createState() => _VenueEditScreenState();
}

class _VenueEditScreenState extends ConsumerState<VenueEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _mapsUrl;
  late VenueEditViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _address = TextEditingController();
    _mapsUrl = TextEditingController();
    _viewModel = ref.read(venueEditViewModelProvider(widget.venueId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final venue = widget.venue;
      if (venue != null) {
        _viewModel.init(venue);
        _name.text = venue.name;
        _address.text = venue.address ?? '';
        _mapsUrl.text = venue.mapsUrl ?? '';
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _mapsUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = ref.read(venueEditViewModelProvider(widget.venueId));
    final success = await vm.save();
    if (!mounted) return;
    if (success) {
      ref.read(venueListViewModelProvider).load(forceRefresh: true);
      ref.invalidate(venueDetailViewModelProvider(widget.venueId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campo atualizado com sucesso')),
      );
      context.go('/venues/${widget.venueId}');
    }
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

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Editar campo',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.venues, route: '/venues'),
        BreadcrumbItem('Editar'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLayout.form(
            child: Form(
              key: _formKey,
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final vm2 = ref.watch(
                            venueEditViewModelProvider(widget.venueId),
                          );
                          final orgId = vm2.organizationId;
                          final orgAsync = orgId != null && orgId.isNotEmpty
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
                      const SizedBox(height: 12),
                      KicksterInput(
                        label: 'Nome',
                        controller: _name,
                        onChanged: (value) => _viewModel.setName(value),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      KicksterInput(
                        label: 'Endereço',
                        controller: _address,
                        onChanged: (value) => _viewModel.setAddress(value),
                      ),
                      const SizedBox(height: 12),
                      KicksterInput(
                        label: 'URL do mapa',
                        controller: _mapsUrl,
                        keyboardType: TextInputType.url,
                        hintText: 'Ex.: https://maps.app.goo.gl/...',
                        onChanged: (value) => _viewModel.setMapsUrl(value),
                        validator: _validateMapsUrl,
                      ),
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _viewModel.errorMessage!,
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                      const SizedBox(height: 24),
                      KicksterButton(
                        label: 'Salvar',
                        icon: Icons.check,
                        loading: _viewModel.isSubmitting,
                        onPressed: _viewModel.isSubmitting ? null : _save,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
