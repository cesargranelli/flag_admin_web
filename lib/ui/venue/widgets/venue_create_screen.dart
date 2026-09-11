import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/ui/venue/view_models/venue_create_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulário de criação de campo de jogo.
class VenueCreateScreen extends ConsumerStatefulWidget {
  const VenueCreateScreen({super.key});

  @override
  ConsumerState<VenueCreateScreen> createState() => _VenueCreateScreenState();
}

class _VenueCreateScreenState extends ConsumerState<VenueCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _mapsUrl;
  late VenueCreateViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _address = TextEditingController();
    _mapsUrl = TextEditingController();
    _viewModel = ref.read(venueCreateViewModelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.init();
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
    final vm = ref.read(venueCreateViewModelProvider);
    final success = await vm.save();
    if (!mounted) return;
    if (success) {
      ref.read(venueListViewModelProvider).load(forceRefresh: true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Campo criado com sucesso')));
      context.go('/venues');
    } else {
      // Erro já foi setado no ViewModel (ex: 'Preencha todos os campos obrigatórios' ou 'Não foi possível salvar')
      // O errorMessage já está disponível via _viewModel.errorMessage
      if (_viewModel.errorMessage != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
      }
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
    final organizations = ref.watch(organizationsProvider);

    return AppScreen(
      title: 'Novo campo',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.venues, route: '/venues'),
        BreadcrumbItem('Novo'),
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
                      organizations.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => AppErrorState(
                          message: 'Erro ao carregar organizações',
                          onRetry: () => ref.invalidate(organizationsProvider),
                        ),
                        data: (orgs) {
                          if (orgs.isEmpty) {
                            return const AppEmptyState(
                              message:
                                  'Cadastre uma organização antes de criar campos',
                              icon: Icons.business,
                            );
                          }
                          return KicksterDropdown<String>(
                            label: 'Organização',
                            value: _viewModel.organizationId,
                            items: orgs
                                .map(
                                  (o) => DropdownMenuItem(
                                    value: o.id,
                                    child: Text(o.tradeName),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                _viewModel.setOrganizationId(value),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Selecione a organização'
                                : null,
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
