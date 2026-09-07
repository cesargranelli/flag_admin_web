import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'components/institution_identity_section.dart';

/// Formulário de criação e edição de agremiação (camada Views - ADR-001 / MVVM / Kickster).
class InstitutionFormScreen extends ConsumerStatefulWidget {
  final String? id;
  final Institution? institution;

  const InstitutionFormScreen({
    super.key,
    this.id,
    this.institution,
  });

  @override
  ConsumerState<InstitutionFormScreen> createState() =>
      _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends ConsumerState<InstitutionFormScreen> {
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

  @override
  void initState() {
    super.initState();
    final inst = widget.institution;

    _tradeName = TextEditingController(text: inst?.tradeName ?? inst?.name ?? '');
    _legalName = TextEditingController(text: inst?.legalName ?? inst?.name ?? '');
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
      text: inst?.primaryColor ?? (inst != null && inst.colors.isNotEmpty ? inst.colors[0] : '#FD6B22'),
    );
    _secondaryColor = TextEditingController(
      text: inst?.secondaryColor ?? (inst != null && inst.colors.length > 1 ? inst.colors[1] : '#1E293B'),
    );
    _tertiaryColor = TextEditingController(
      text: inst?.tertiaryColor ?? (inst != null && inst.colors.length > 2 ? inst.colors[2] : ''),
    );
    _quaternaryColor = TextEditingController(
      text: inst?.quaternaryColor ?? (inst != null && inst.colors.length > 3 ? inst.colors[3] : ''),
    );

    if (inst != null) {
      _type = inst.type;
      _documentType = inst.documentType ?? DocumentType.cnpj;
      _country = inst.country.isNotEmpty ? inst.country : 'BR';
      _selectedOrgs = List.from(inst.organizations);
    } else if (widget.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final fetched =
            await ref.read(institutionRepositoryProvider).getInstitution(widget.id!);
        if (mounted) {
          setState(() {
            _tradeName.text = fetched.tradeName.isNotEmpty ? fetched.tradeName : fetched.name;
            _legalName.text = fetched.legalName.isNotEmpty ? fetched.legalName : fetched.name;
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
            _primaryColor.text = fetched.primaryColor ?? (fetched.colors.isNotEmpty ? fetched.colors[0] : '#FD6B22');
            _secondaryColor.text = fetched.secondaryColor ?? (fetched.colors.length > 1 ? fetched.colors[1] : '#1E293B');
            _tertiaryColor.text = fetched.tertiaryColor ?? (fetched.colors.length > 2 ? fetched.colors[2] : '');
            _quaternaryColor.text = fetched.quaternaryColor ?? (fetched.colors.length > 3 ? fetched.colors[3] : '');
            _type = fetched.type;
            _documentType = fetched.documentType ?? DocumentType.cnpj;
            _country = fetched.country.isNotEmpty ? fetched.country : 'BR';
            _selectedOrgs = List.from(fetched.organizations);
          });
        }
      });
    }

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

    final formVm = ref.read(institutionFormViewModelProvider);

    final colors = <String>[];
    if (_primaryColor.text.trim().isNotEmpty) colors.add(_primaryColor.text.trim());
    if (_secondaryColor.text.trim().isNotEmpty) colors.add(_secondaryColor.text.trim());
    if (_tertiaryColor.text.trim().isNotEmpty) colors.add(_tertiaryColor.text.trim());
    if (_quaternaryColor.text.trim().isNotEmpty) colors.add(_quaternaryColor.text.trim());

    final success = await formVm.save(
      id: widget.id,
      name: _tradeName.text.trim(),
      tradeName: _tradeName.text.trim(),
      legalName: _legalName.text.trim(),
      type: _type,
      abbreviation: _abbreviation.text.trim().isNotEmpty ? _abbreviation.text.trim() : null,
      document: _document.text.trim().isNotEmpty ? _document.text.trim() : null,
      documentType: _documentType,
      presidentName: _presidentName.text.trim().isNotEmpty ? _presidentName.text.trim() : null,
      presidentCpf: _presidentCpf.text.trim().isNotEmpty ? _presidentCpf.text.trim() : null,
      email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
      phone: _phone.text.trim().isNotEmpty ? _phone.text.trim() : null,
      website: _website.text.trim().isNotEmpty ? _website.text.trim() : null,
      instagram: _instagram.text.trim().isNotEmpty ? _instagram.text.trim() : null,
      country: _country,
      state: _state.text.trim().isNotEmpty ? _state.text.trim() : null,
      city: _city.text.trim().isNotEmpty ? _city.text.trim() : null,
      logoUrl: _logoUrl.text.trim().isNotEmpty ? _logoUrl.text.trim() : null,
      primaryColor: _primaryColor.text.trim().isNotEmpty ? _primaryColor.text.trim() : null,
      secondaryColor: _secondaryColor.text.trim().isNotEmpty ? _secondaryColor.text.trim() : null,
      tertiaryColor: _tertiaryColor.text.trim().isNotEmpty ? _tertiaryColor.text.trim() : null,
      quaternaryColor: _quaternaryColor.text.trim().isNotEmpty ? _quaternaryColor.text.trim() : null,
      colors: colors,
      organizationIds: _selectedOrgs,
    );

    if (!mounted) return;

    if (success) {
      _saved = true;
      ref.invalidate(institutionsProvider);
      ref.read(institutionViewModelProvider).load(forceRefresh: true);
      if (widget.id != null) {
        ref.invalidate(institutionProvider(widget.id!));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agremiação salva com sucesso!')),
      );
      context.go('/institutions');
    } else {
      setState(() {
        _errorMessage =
            formVm.errorMessage ?? 'Não foi possível salvar a agremiação.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(institutionFormViewModelProvider).isSubmitting;
    final orgsAsync = ref.watch(organizationsProvider);
    final isEditing = widget.id != null;
    final title = isEditing ? 'Editar Agremiação' : 'Nova Agremiação';

    return PopScope(
      canPop: !_hasChanges || isSubmitting || _saved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.canPop()) context.pop();
      },
      child: AppScreen(
        title: title,
        breadcrumb: [
          const BreadcrumbItem(AppStrings.home, route: '/'),
          const BreadcrumbItem(AppStrings.institutions, route: '/institutions'),
          BreadcrumbItem(isEditing ? 'Editar' : 'Nova'),
        ],
        body: AppLayout.form(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),

                // 1. DADOS BÁSICOS
                const KicksterSectionTitle(
                  title: 'Dados Básicos',
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 12),
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
                  hintText: 'Ex: Associação Esportiva Spartans de Flag Football',
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: KicksterDropdown<InstitutionType>(
                        label: 'Tipo de Agremiação *',
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
                        label: 'Sigla / Abreviação',
                        controller: _abbreviation,
                        hintText: 'Ex: SPS, POLI',
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
                        label: 'Tipo de Documento',
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
                        label: 'Número do Documento (CNPJ)',
                        controller: _document,
                        hintText: '00.000.000/0000-00',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. PRESIDENTE / REPRESENTANTE
                const KicksterSectionTitle(
                  title: 'Representação & Diretoria',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),

                // 3. CONTATO & REDES
                const KicksterSectionTitle(
                  title: 'Contato & Redes Sociais',
                  icon: Icons.contact_mail_outlined,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),

                // 4. LOCALIZAÇÃO
                const KicksterSectionTitle(
                  title: 'Localização',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: KicksterInput(
                        label: 'Cidade',
                        controller: _city,
                        hintText: 'Ex: São Paulo',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KicksterInput(
                        label: 'Estado (UF)',
                        controller: _state,
                        hintText: 'Ex: SP',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. IDENTIDADE VISUAL & CORES (KICKSTER)
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

                // 6. FILIAÇÃO A ORGANIZAÇÕES
                const KicksterSectionTitle(
                  title: 'Filiação a Organizações',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 12),
                orgsAsync.when(
                  data: (orgs) {
                    if (orgs.isEmpty) {
                      return const Text(
                        'Nenhuma organização cadastrada na plataforma.',
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: orgs.map((org) {
                        final selected = _selectedOrgs.contains(org.id);
                        return FilterChip(
                          label: Text(org.tradeName.isNotEmpty ? org.tradeName : org.legalName),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedOrgs.add(org.id);
                              } else {
                                _selectedOrgs.remove(org.id);
                              }
                            });
                            _markDirty();
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const AppLoading(),
                  error: (err, _) => Text(
                    'Erro ao carregar organizações: $err',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 32),

                // BOTÕES DE AÇÃO
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    KicksterButton(
                      label: 'Cancelar',
                      variant: KicksterButtonVariant.outline,
                      onPressed: isSubmitting ? null : () => context.pop(),
                    ),
                    const SizedBox(width: 16),
                    KicksterButton(
                      label: isSubmitting ? 'Salvando...' : 'Salvar Agremiação',
                      icon: Icons.check,
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
}
