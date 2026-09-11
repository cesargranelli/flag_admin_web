import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'components/institution_identity_section.dart';

/// Tela dedicada EXCLUSIVAMENTE à EDIÇÃO de agremiação existente (ADR-001 / MVVM 1:1).
///
/// Responsabilidade única: carregar a entidade existente pelo ID e salvar as alterações.
class InstitutionEditScreen extends ConsumerStatefulWidget {
  final String id;
  final Institution? institution;

  const InstitutionEditScreen({super.key, required this.id, this.institution});

  @override
  ConsumerState<InstitutionEditScreen> createState() =>
      _InstitutionEditScreenState();
}

class _InstitutionEditScreenState extends ConsumerState<InstitutionEditScreen> {
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

  InstitutionType _type = InstitutionType.club;
  DocumentType? _documentType = DocumentType.cnpj;
  String _country = 'BR';
  List<String> _selectedOrgs = [];

  bool _hasChanges = false;
  bool _saved = false;
  String? _errorMessage;

  List<CountryOption> get _countryOptionList {
    final list = [...countryOptions];
    if (_country.isNotEmpty && !list.any((c) => c.code == _country)) {
      list.insert(0, CountryOption(_country, _country));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    final inst = widget.institution;

    _tradeName = TextEditingController(
      text: inst?.tradeName ?? inst?.name ?? '',
    );
    _legalName = TextEditingController(
      text: inst?.legalName ?? inst?.name ?? '',
    );
    _abbreviation = TextEditingController(text: inst?.abbreviation ?? '');
    _document = TextEditingController(text: inst?.document ?? '');
    _presidentName = TextEditingController(text: inst?.presidentName ?? '');
    _presidentCpf = TextEditingController(text: inst?.presidentCpf ?? '');
    _email = TextEditingController(text: inst?.email ?? '');
    _phone = TextEditingController(text: inst?.phone ?? '');
    _website = TextEditingController(text: inst?.website ?? '');
    _instagram = TextEditingController(text: inst?.instagram ?? '');
    _state = TextEditingController(text: inst?.state ?? '');
    _city = TextEditingController(text: inst?.city ?? '');
    _logoUrl = TextEditingController(text: inst?.logoUrl ?? '');
    _primaryColor = TextEditingController(
      text:
          inst?.primaryColor ??
          (inst != null && inst.colors.isNotEmpty ? inst.colors[0] : '#FD6B22'),
    );
    _secondaryColor = TextEditingController(
      text:
          inst?.secondaryColor ??
          (inst != null && inst.colors.length > 1 ? inst.colors[1] : '#1E293B'),
    );
    _tertiaryColor = TextEditingController(
      text:
          inst?.tertiaryColor ??
          (inst != null && inst.colors.length > 2 ? inst.colors[2] : ''),
    );
    _quaternaryColor = TextEditingController(
      text:
          inst?.quaternaryColor ??
          (inst != null && inst.colors.length > 3 ? inst.colors[3] : ''),
    );

    if (inst != null) {
      _type = inst.type;
      _documentType = inst.documentType ?? DocumentType.cnpj;
      _country = inst.country.isNotEmpty ? inst.country : 'BR';
      _selectedOrgs = List.from(inst.organizations);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final editVm = ref.read(institutionEditViewModelProvider(widget.id));
      await editVm.load();
      final loaded = editVm.institution;
      if (mounted && loaded != null) {
        setState(() {
          _tradeName.text = loaded.tradeName.isNotEmpty
              ? loaded.tradeName
              : loaded.name;
          _legalName.text = loaded.legalName.isNotEmpty
              ? loaded.legalName
              : loaded.name;
          _abbreviation.text = loaded.abbreviation ?? '';
          _document.text = loaded.document ?? '';
          _presidentName.text = loaded.presidentName ?? '';
          _presidentCpf.text = loaded.presidentCpf ?? '';
          _email.text = loaded.email ?? '';
          _phone.text = loaded.phone ?? '';
          _website.text = loaded.website ?? '';
          _instagram.text = loaded.instagram ?? '';
          _state.text = loaded.state ?? '';
          _city.text = loaded.city ?? '';
          _logoUrl.text = loaded.logoUrl ?? '';
          _primaryColor.text =
              loaded.primaryColor ??
              (loaded.colors.isNotEmpty ? loaded.colors[0] : '#FD6B22');
          _secondaryColor.text =
              loaded.secondaryColor ??
              (loaded.colors.length > 1 ? loaded.colors[1] : '#1E293B');
          _tertiaryColor.text =
              loaded.tertiaryColor ??
              (loaded.colors.length > 2 ? loaded.colors[2] : '');
          _quaternaryColor.text =
              loaded.quaternaryColor ??
              (loaded.colors.length > 3 ? loaded.colors[3] : '');
          _type = loaded.type;
          _documentType = loaded.documentType ?? DocumentType.cnpj;
          _country = loaded.country.isNotEmpty ? loaded.country : 'BR';
          _selectedOrgs = List.from(loaded.organizations);
        });
      }
    });

    _tradeName.addListener(_markDirty);
    _legalName.addListener(_markDirty);
    _abbreviation.addListener(_markDirty);
    _document.addListener(_markDirty);
    _presidentName.addListener(_markDirty);
    _presidentCpf.addListener(_markDirty);
    _email.addListener(_markDirty);
    _phone.addListener(_markDirty);
    _website.addListener(_markDirty);
    _instagram.addListener(_markDirty);
    _state.addListener(_markDirty);
    _city.addListener(_markDirty);
    _logoUrl.addListener(_markDirty);
    _primaryColor.addListener(_markDirty);
    _secondaryColor.addListener(_markDirty);
    _tertiaryColor.addListener(_markDirty);
    _quaternaryColor.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _tradeName.dispose();
    _legalName.dispose();
    _abbreviation.dispose();
    _document.dispose();
    _presidentName.dispose();
    _presidentCpf.dispose();
    _email.dispose();
    _phone.dispose();
    _website.dispose();
    _instagram.dispose();
    _state.dispose();
    _city.dispose();
    _logoUrl.dispose();
    _primaryColor.dispose();
    _secondaryColor.dispose();
    _tertiaryColor.dispose();
    _quaternaryColor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final editVm = ref.read(institutionEditViewModelProvider(widget.id));

    final colors = <String>[];
    if (_primaryColor.text.trim().isNotEmpty)
      colors.add(_primaryColor.text.trim());
    if (_secondaryColor.text.trim().isNotEmpty)
      colors.add(_secondaryColor.text.trim());
    if (_tertiaryColor.text.trim().isNotEmpty)
      colors.add(_tertiaryColor.text.trim());
    if (_quaternaryColor.text.trim().isNotEmpty)
      colors.add(_quaternaryColor.text.trim());

    final success = await editVm.update(
      name: _tradeName.text.trim(),
      tradeName: _tradeName.text.trim(),
      legalName: _legalName.text.trim(),
      type: _type,
      abbreviation: _abbreviation.text.trim().isNotEmpty
          ? _abbreviation.text.trim()
          : null,
      document: _document.text.trim().isNotEmpty ? _document.text.trim() : null,
      documentType: _documentType,
      presidentName: _presidentName.text.trim().isNotEmpty
          ? _presidentName.text.trim()
          : null,
      presidentCpf: _presidentCpf.text.trim().isNotEmpty
          ? _presidentCpf.text.trim()
          : null,
      email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
      phone: _phone.text.trim().isNotEmpty ? _phone.text.trim() : null,
      website: _website.text.trim().isNotEmpty ? _website.text.trim() : null,
      instagram: _instagram.text.trim().isNotEmpty
          ? _instagram.text.trim()
          : null,
      country: _country,
      state: _state.text.trim().isNotEmpty ? _state.text.trim() : null,
      city: _city.text.trim().isNotEmpty ? _city.text.trim() : null,
      logoUrl: _logoUrl.text.trim().isNotEmpty ? _logoUrl.text.trim() : null,
      primaryColor: _primaryColor.text.trim().isNotEmpty
          ? _primaryColor.text.trim()
          : null,
      secondaryColor: _secondaryColor.text.trim().isNotEmpty
          ? _secondaryColor.text.trim()
          : null,
      tertiaryColor: _tertiaryColor.text.trim().isNotEmpty
          ? _tertiaryColor.text.trim()
          : null,
      quaternaryColor: _quaternaryColor.text.trim().isNotEmpty
          ? _quaternaryColor.text.trim()
          : null,
      colors: colors,
      organizationIds: _selectedOrgs,
    );

    if (!mounted) return;

    if (success) {
      _saved = true;
      ref.invalidate(institutionsProvider);
      ref.invalidate(institutionProvider(widget.id));
      ref.read(institutionViewModelProvider).load(forceRefresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agremiação atualizada com sucesso!')),
      );
      context.go('/institutions');
    } else {
      setState(() {
        _errorMessage =
            editVm.errorMessage ?? 'Não foi possível salvar a agremiação.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editVm = ref.watch(institutionEditViewModelProvider(widget.id));
    final isSubmitting = editVm.isSubmitting;
    final isLoading = editVm.isLoading && editVm.institution == null;

    return PopScope(
      canPop: !_hasChanges || isSubmitting || _saved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.canPop()) context.pop();
      },
      child: AppScreen(
        title: 'Editar Agremiação',
        breadcrumb: const [
          BreadcrumbItem(AppStrings.home, route: '/'),
          BreadcrumbItem(AppStrings.institutions, route: '/institutions'),
          BreadcrumbItem('Editar'),
        ],
        body: isLoading
            ? const AppLoading(message: 'Carregando dados da agremiação...')
            : AppLayout.form(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) _errorBanner(_errorMessage!),

                      // 1. DADOS BÁSICOS
                      _section('Dados básicos', Icons.business_outlined, [
                        KicksterInput(
                          label: 'Nome Fantasia *',
                          controller: _tradeName,
                          hintText: 'Ex: São Paulo Spartans, Poli Flag...',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o nome fantasia'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        KicksterInput(
                          label: 'Razão Social',
                          controller: _legalName,
                          hintText:
                              'Ex: Associação Esportiva Spartans de Flag Football',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: KicksterDropdown<InstitutionType>(
                                label: '',
                                hint: 'Tipo de agremiação',
                                value: _type,
                                items: InstitutionType.values.map((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Row(
                                      children: [
                                        Icon(institutionTypeIcon(t), size: 18),
                                        const SizedBox(width: 8),
                                        Text(t.label),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _type = v);
                                    _markDirty();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: KicksterInput(
                                label: '',
                                controller: _abbreviation,
                                hintText: 'Sigla / Abreviação',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: KicksterDropdown<DocumentType>(
                                label: '',
                                hint: 'Tipo de Documento',
                                value: _documentType,
                                items: DocumentType.values.map((d) {
                                  return DropdownMenuItem(
                                    value: d,
                                    child: Text(d.label),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() => _documentType = v);
                                  _markDirty();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: KicksterInput(
                                label: '',
                                controller: _document,
                                hintText: 'Número do Documento',
                              ),
                            ),
                          ],
                        ),
                      ]),

                      // 2. PRESIDENTE / REPRESENTANTE
                      _section(
                        'Representação & Diretoria',
                        Icons.person_outline,
                        [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: KicksterInput(
                                  label: 'Nome do Presidente / Representante',
                                  controller: _presidentName,
                                  hintText: 'Ex: João Silva',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: KicksterInput(
                                  label: 'CPF do Presidente',
                                  controller: _presidentCpf,
                                  hintText: '000.000.000-00',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 3. CONTATO & REDES
                      _section('Contato', Icons.contact_mail_outlined, [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: KicksterInput(
                                label: 'E-mail Oficial',
                                controller: _email,
                                hintText: 'contato@time.com.br',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: KicksterInput(
                                label: 'Telefone / WhatsApp',
                                controller: _phone,
                                hintText: '(11) 99999-9999',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: KicksterInput(
                                label: 'Site Oficial',
                                controller: _website,
                                hintText: 'https://seutime.com.br',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: KicksterInput(
                                label: 'Instagram (@)',
                                controller: _instagram,
                                hintText: '@seutimeflag',
                              ),
                            ),
                          ],
                        ),
                      ]),

                      // 4. LOCALIZAÇÃO
                      _section('Localização', Icons.location_on_outlined, [
                        _countryDropdown(),
                        const SizedBox(height: 12),
                        if (_country == 'BR')
                          _stateDropdown()
                        else
                          KicksterInput(
                            label: 'Estado (opcional)',
                            controller: _state,
                          ),
                        const SizedBox(height: 12),
                        KicksterInput(
                          label: 'Cidade (opcional)',
                          controller: _city,
                          hintText: 'Ex: São Paulo',
                        ),
                      ]),

                      // 5. IDENTIDADE VISUAL & CORES
                      InstitutionIdentitySection(
                        nameController: _tradeName,
                        abbreviationController: _abbreviation,
                        logoUrlController: _logoUrl,
                        primaryColorController: _primaryColor,
                        secondaryColorController: _secondaryColor,
                        tertiaryColorController: _tertiaryColor,
                        quaternaryColorController: _quaternaryColor,
                        onDirty: _markDirty,
                      ),
                      const SizedBox(height: 24),

                      // BOTÕES DE AÇÃO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          KicksterButton(
                            label: 'Cancelar',
                            variant: KicksterButtonVariant.outline,
                            onPressed: isSubmitting
                                ? null
                                : () => context.pop(),
                          ),
                          const SizedBox(width: 16),
                          KicksterButton(
                            label: isSubmitting
                                ? 'Salvando...'
                                : 'Salvar alterações',
                            icon: Icons.check,
                            loading: isSubmitting,
                            onPressed: isSubmitting ? null : _save,
                          ),
                        ],
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
      margin: const EdgeInsets.only(bottom: 16),
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

  Widget _countryDropdown() {
    return KicksterDropdown<String>(
      label: 'País',
      value: _country,
      values: [for (final c in _countryOptionList) c.code],
      labels: [for (final c in _countryOptionList) c.name],
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
}
