import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/domain_imports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flag_admin_web/config/providers/providers.dart';
import 'components/organization_identity_section.dart';

/// Tela dedicada EXCLUSIVAMENTE à EDIÇÃO de Organização existente (ADR-001 / MVVM 1:1).
///
/// Responsabilidade única: carregar a entidade existente pelo ID e salvar as alterações.
class OrganizationEditScreen extends ConsumerStatefulWidget {
  final String id;
  final Organization? organization;

  const OrganizationEditScreen({
    super.key,
    required this.id,
    this.organization,
  });

  @override
  ConsumerState<OrganizationEditScreen> createState() =>
      _OrganizationEditScreenState();
}

class _OrganizationEditScreenState
    extends ConsumerState<OrganizationEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tradeName;
  late final TextEditingController _legalName;
  late final TextEditingController _abbreviation;
  late final TextEditingController _document;
  late final TextEditingController _presidentName;
  late final TextEditingController _presidentCpf;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _instagram;
  late final TextEditingController _state;
  late final TextEditingController _city;
  late final TextEditingController _logoUrl;
  late final TextEditingController _primaryColor;
  late final TextEditingController _secondaryColor;
  late final TextEditingController _tertiaryColor;
  late final TextEditingController _quaternaryColor;
  late final TextEditingController _locale;

  String _country = 'BR';
  final _timezone = 'America/Sao_Paulo';

  OrganizationType? _type;
  DocumentType? _documentType = DocumentType.cnpj;
  bool _saved = false;
  bool _hasChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;

    _tradeName = TextEditingController(text: org?.tradeName ?? '');
    _legalName = TextEditingController(text: org?.legalName ?? '');
    _abbreviation = TextEditingController(text: org?.abbreviation ?? '');
    _document = TextEditingController(text: org?.document ?? '');
    _presidentName = TextEditingController(text: org?.presidentName ?? '');
    _presidentCpf = TextEditingController(text: org?.presidentCpf ?? '');
    _email = TextEditingController(text: org?.email ?? '');
    _phone = TextEditingController(text: org?.phone ?? '');
    _website = TextEditingController(text: org?.website ?? '');
    _instagram = TextEditingController(text: org?.instagram ?? '');
    _state = TextEditingController(text: org?.state ?? '');
    _city = TextEditingController(text: org?.city ?? '');
    _logoUrl = TextEditingController(text: org?.logoUrl ?? '');
    _primaryColor = TextEditingController(text: org?.primaryColor ?? '#FD6B22');
    _secondaryColor = TextEditingController(
      text: org?.secondaryColor ?? '#1E293B',
    );
    _tertiaryColor = TextEditingController(text: org?.tertiaryColor ?? '');
    _quaternaryColor = TextEditingController(text: org?.quaternaryColor ?? '');
    _locale = TextEditingController(text: org?.locale ?? 'pt-BR');
    _country = org?.country.isNotEmpty == true ? org!.country : 'BR';
    _type = org?.organizationType;
    _documentType = org?.documentType ?? DocumentType.cnpj;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(organizationEditViewModelProvider(widget.id));
      await vm.load();
      if (mounted && vm.organization != null) {
        final fetched = vm.organization!;
        setState(() {
          _tradeName.text = fetched.tradeName;
          _legalName.text = fetched.legalName;
          _abbreviation.text = fetched.abbreviation ?? '';
          _document.text = fetched.document ?? '';
          _presidentName.text = fetched.presidentName ?? '';
          _presidentCpf.text = fetched.presidentCpf ?? '';
          _email.text = fetched.email ?? '';
          _phone.text = fetched.phone ?? '';
          _website.text = fetched.website ?? '';
          _instagram.text = fetched.instagram ?? '';
          _state.text = fetched.state ?? '';
          _city.text = fetched.city ?? '';
          _logoUrl.text = fetched.logoUrl ?? '';
          _primaryColor.text = fetched.primaryColor ?? '#FD6B22';
          _secondaryColor.text = fetched.secondaryColor ?? '#1E293B';
          _tertiaryColor.text = fetched.tertiaryColor ?? '';
          _quaternaryColor.text = fetched.quaternaryColor ?? '';
          _locale.text = fetched.locale;
          _country = fetched.country.isNotEmpty ? fetched.country : 'BR';
          _type = fetched.organizationType;
          _documentType = fetched.documentType ?? DocumentType.cnpj;
        });
      }
    });

    for (final controller in [
      _tradeName,
      _legalName,
      _abbreviation,
      _document,
      _presidentName,
      _presidentCpf,
      _email,
      _phone,
      _website,
      _instagram,
      _state,
      _city,
      _logoUrl,
      _primaryColor,
      _secondaryColor,
      _tertiaryColor,
      _quaternaryColor,
      _locale,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (_saved || _hasChanges) return;
    setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    for (final controller in [
      _tradeName,
      _legalName,
      _abbreviation,
      _document,
      _presidentName,
      _presidentCpf,
      _email,
      _phone,
      _website,
      _instagram,
      _state,
      _city,
      _logoUrl,
      _primaryColor,
      _secondaryColor,
      _tertiaryColor,
      _quaternaryColor,
      _locale,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildBody() => {
    'legalName': _legalName.text.trim(),
    'tradeName': _tradeName.text.trim(),
    if (_abbreviation.text.trim().isNotEmpty)
      'abbreviation': _abbreviation.text.trim(),
    'organizationType': _type!.toJson(),
    if (_document.text.trim().isNotEmpty)
      'document': _document.text.trim().replaceAll(RegExp(r'\D'), ''),
    if (_documentType != null) 'documentType': _documentType!.toJson(),
    if (_presidentName.text.trim().isNotEmpty)
      'presidentName': _presidentName.text.trim(),
    if (_presidentCpf.text.trim().isNotEmpty)
      'presidentCpf': _presidentCpf.text.trim().replaceAll(RegExp(r'\D'), ''),
    if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
    if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
    if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
    if (_instagram.text.trim().isNotEmpty) 'instagram': _instagram.text.trim(),
    'country': _country,
    if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
    if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
    if (_logoUrl.text.trim().isNotEmpty) 'logoUrl': _logoUrl.text.trim(),
    if (_primaryColor.text.trim().isNotEmpty)
      'primaryColor': _primaryColor.text.trim(),
    if (_secondaryColor.text.trim().isNotEmpty)
      'secondaryColor': _secondaryColor.text.trim(),
    if (_tertiaryColor.text.trim().isNotEmpty)
      'tertiaryColor': _tertiaryColor.text.trim(),
    if (_quaternaryColor.text.trim().isNotEmpty)
      'quaternaryColor': _quaternaryColor.text.trim(),
    'timezone': _timezone,
    'locale': _locale.text.trim(),
  };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final vm = ref.read(organizationEditViewModelProvider(widget.id));
    final body = _buildBody();
    final success = await vm.updateOrganization(body);
    if (!mounted) return;

    if (success && vm.updatedOrganization != null) {
      _saved = true;
      ref.invalidate(organizationsProvider);
      ref.invalidate(organizationProvider(widget.id));
      ref.read(organizationViewModelProvider).load(forceRefresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organização atualizada com sucesso')),
      );
      context.go('/organizations/${widget.id}');
    } else {
      setState(() {
        _errorMessage =
            vm.errorMessage ?? 'Não foi possível atualizar a organização.';
      });
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/organizations/${widget.id}');
    }
  }

  Future<void> _handleBack() async {
    final isSubmitting = ref
        .read(organizationEditViewModelProvider(widget.id))
        .isSubmitting;
    if (_hasChanges && !isSubmitting && !_saved) {
      final discard = await showKicksterConfirm(
        context: context,
        title: 'Descartar alterações?',
        content: 'As alterações não salvas serão perdidas.',
        confirmLabel: 'Descartar',
        cancelLabel: 'Continuar editando',
        danger: true,
      );
      if (discard != true) return;
      if (!mounted) return;
      _saved = true;
    }
    if (!mounted) return;
    _goBack();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(organizationEditViewModelProvider(widget.id));
    final isSubmitting = vm.isSubmitting;

    return PopScope(
      canPop: !_hasChanges || isSubmitting || _saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AppScreen(
        title: 'Editar organização',
        breadcrumb: [
          const BreadcrumbItem(AppStrings.home, route: '/'),
          const BreadcrumbItem(
            AppStrings.organizations,
            route: '/organizations',
          ),
          BreadcrumbItem(widget.organization?.tradeName ?? 'Editar'),
        ],
        body: vm.isLoading
            ? const AppLoading(message: 'Carregando dados da organização...')
            : AppLayout.form(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) _errorBanner(_errorMessage!),
                      _section('Dados básicos', Icons.business_outlined, [
                        _field(
                          'Nome fantasia',
                          _tradeName,
                          hint: 'Informe o nome fantasia',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o nome fantasia'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          'Razão social',
                          _legalName,
                          hint: 'Informe a razão social',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe a razão social'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _field('Sigla (opcional)', _abbreviation),
                        const SizedBox(height: 12),
                        _typeDropdown(),
                        const SizedBox(height: 12),
                        _documentField(),
                      ]),
                      _section('Presidente', Icons.person_outline, [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _field(
                                'Nome do presidente',
                                _presidentName,
                                hint: 'Informe o nome do presidente',
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Informe o nome do presidente'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(flex: 1, child: _presidentCpfField()),
                          ],
                        ),
                      ]),
                      _section('Contato', Icons.contact_mail_outlined, [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _emailField()),
                            const SizedBox(width: 12),
                            Expanded(child: _phoneField()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _websiteField()),
                            const SizedBox(width: 12),
                            Expanded(child: _instagramField()),
                          ],
                        ),
                      ]),
                      _section('Localização', Icons.location_on_outlined, [
                        _countryDropdown(),
                        const SizedBox(height: 12),
                        if (_country == 'BR')
                          _stateDropdown()
                        else
                          _field('Estado (opcional)', _state),
                        const SizedBox(height: 12),
                        _field('Cidade (opcional)', _city),
                      ]),
                      OrganizationIdentitySection(
                        tradeNameController: _tradeName,
                        abbreviationController: _abbreviation,
                        logoUrlController: _logoUrl,
                        primaryColorController: _primaryColor,
                        secondaryColorController: _secondaryColor,
                        tertiaryColorController: _tertiaryColor,
                        quaternaryColorController: _quaternaryColor,
                        localeController: _locale,
                        localeOptions: const [
                          ('pt-BR', 'Português (Brasil)'),
                          ('en-US', 'English (US)'),
                          ('es-ES', 'Español'),
                        ],
                        onDirty: _markDirty,
                      ),
                      const SizedBox(height: 16),
                      KicksterButton(
                        label: isSubmitting
                            ? 'Salvando alterações...'
                            : 'Salvar alterações',
                        icon: Icons.check,
                        loading: isSubmitting,
                        onPressed: isSubmitting ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(title: title, icon: icon),
        const SizedBox(height: 12),
        _card(null, children),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _card(String? title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _typeDropdown() {
    return KicksterDropdown<OrganizationType>(
      label: '',
      hint: 'Tipo de organização',
      value: _type,
      items: OrganizationType.values
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: appDropdownItem(organizationTypeIcon(t), _typeLabel(t)),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => _type = value);
        _markDirty();
      },
      validator: (value) =>
          value == null ? 'Selecione o tipo da organização' : null,
    );
  }

  Widget _documentField() {
    return KicksterInput(
      label: 'CNPJ (opcional)',
      controller: _document,
      keyboardType: TextInputType.number,
      hintText: '00.000.000/0000-00',
      onChanged: (value) {
        final masked = DocumentUtils.maskCnpj(value);
        if (masked != value) {
          _document.value = TextEditingValue(
            text: masked,
            selection: TextSelection.collapsed(offset: masked.length),
          );
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        return DocumentUtils.isValidCnpj(value) ? null : 'Documento inválido';
      },
    );
  }

  Widget _presidentCpfField() {
    return KicksterInput(
      label: 'CPF do presidente',
      controller: _presidentCpf,
      keyboardType: TextInputType.number,
      hintText: '000.000.000-00',
      onChanged: (value) {
        final masked = DocumentUtils.maskCpf(value);
        if (masked != value) {
          _presidentCpf.value = TextEditingValue(
            text: masked,
            selection: TextSelection.collapsed(offset: masked.length),
          );
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe o CPF do presidente';
        }
        return DocumentUtils.isValidCpf(value) ? null : 'CPF inválido';
      },
    );
  }

  Widget _emailField() {
    return KicksterInput(
      label: 'E-mail (opcional)',
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      hintText: 'contato@exemplo.com',
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
            ? null
            : 'E-mail inválido';
      },
    );
  }

  Widget _phoneField() {
    return KicksterInput(
      label: 'Telefone (opcional)',
      controller: _phone,
      keyboardType: TextInputType.phone,
      hintText: '(11) 99999-9999',
      onChanged: (value) {
        final masked = _maskPhone(value);
        if (masked != value) {
          _phone.value = TextEditingValue(
            text: masked,
            selection: TextSelection.collapsed(offset: masked.length),
          );
        }
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final digits = v.replaceAll(RegExp(r'\D'), '');
        return (digits.length == 10 || digits.length == 11)
            ? null
            : 'Telefone inválido';
      },
    );
  }

  Widget _websiteField() {
    return KicksterInput(
      label: 'Site (opcional)',
      controller: _website,
      keyboardType: TextInputType.url,
      hintText: 'https://exemplo.com.br',
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final t = v.trim();
        final uri = Uri.tryParse(t.startsWith('http') ? t : 'https://$t');
        return (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host.isNotEmpty)
            ? null
            : 'URL inválida';
      },
    );
  }

  Widget _instagramField() {
    return KicksterInput(
      label: 'Instagram (opcional)',
      controller: _instagram,
      hintText: '@meuclube',
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final t = v.trim().replaceFirst('@', '');
        return RegExp(r'^[A-Za-z0-9_.]{1,30}$').hasMatch(t)
            ? null
            : 'Usuário inválido';
      },
    );
  }

  Widget _countryDropdown() {
    return KicksterDropdown<String>(
      label: 'País',
      value: _country,
      values: [for (final c in _countryOptions) c.code],
      labels: [for (final c in _countryOptions) c.name],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _country = value;
          _state.clear();
        });
        _markDirty();
      },
    );
  }

  Widget _stateDropdown() {
    return KicksterDropdown<String>(
      label: 'Estado',
      hint: 'Selecione o estado',
      value: _state.text.isEmpty ? null : _state.text,
      values: [for (final uf in brazilUfs) uf.$1],
      labels: [for (final uf in brazilUfs) '${uf.$2} (${uf.$1})'],
      onChanged: (value) {
        setState(() {
          _state.text = value ?? '';
        });
        _markDirty();
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return KicksterInput(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      hintText: hint,
      validator: validator,
    );
  }

  List<CountryOption> get _countryOptions {
    final options = [...countryOptions];
    if (_country.isNotEmpty && !options.any((o) => o.code == _country)) {
      options.insert(0, CountryOption(_country, _country));
    }
    return options;
  }

  String _typeLabel(OrganizationType t) => t.label;

  String _maskPhone(String value) {
    final d = value.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.length <= 2) return d;
    if (d.length <= 7) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    if (d.length <= 11) {
      return '(${d.substring(0, 2)}) ${d.substring(2, d.length - 4)}-'
          '${d.substring(d.length - 4)}';
    }
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-'
        '${d.substring(7, 11)}';
  }
}
