import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'colors_picker_dialog.dart';

/// Formulário de criação e edição de agremiação (camada Views - ADR-001 / MVVM).
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
  late final TextEditingController _nameController;

  InstitutionType _type = InstitutionType.club;
  List<String> _colors = [];
  List<String> _selectedOrgs = [];
  bool _hasChanges = false;
  bool _saved = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final inst = widget.institution;
    _nameController = TextEditingController(text: inst?.name ?? '');
    _nameController.addListener(_markDirty);

    if (inst != null) {
      _type = inst.type;
      _colors = List.from(inst.colors);
      _selectedOrgs = List.from(inst.organizations);
    } else if (widget.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final fetched =
            await ref.read(institutionRepositoryProvider).getInstitution(widget.id!);
        if (mounted) {
          setState(() {
            _nameController.text = fetched.name;
            _type = fetched.type;
            _colors = List.from(fetched.colors);
            _selectedOrgs = List.from(fetched.organizations);
          });
        }
      });
    }
  }

  void _markDirty() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hex) {
    try {
      return Color(
          int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return AppColors.surfaceMuted;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final formVm = ref.read(institutionFormViewModelProvider);
    final success = await formVm.save(
      id: widget.id,
      name: _nameController.text,
      type: _type,
      colors: _colors,
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
        const SnackBar(content: Text('Agremiação salva com sucesso')),
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
    final title = isEditing ? 'Editar agremiação' : 'Nova agremiação';

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
                    margin: const EdgeInsets.only(bottom: 16),
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
                // Dados Básicos
                KicksterInput(
                  label: 'Nome da agremiação',
                  controller: _nameController,
                  hintText: 'Ex: São Paulo Spartans, Poli Flag...',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome da agremiação'
                      : null,
                ),
                const SizedBox(height: 16),
                KicksterDropdown<InstitutionType>(
                  label: 'Tipo',
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
                const SizedBox(height: 20),
                // Cores da agremiação
                Row(
                  children: [
                    const Text(
                      'Cores da Agremiação',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.palette_outlined, size: 18),
                      label: const Text('Editar cores'),
                      onPressed: () async {
                        final res = await showDialog<List<String>>(
                          context: context,
                          builder: (_) =>
                              ColorsPickerDialog(initial: _colors),
                        );
                        if (res != null) {
                          setState(() => _colors = res);
                          _markDirty();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_colors.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _colors.map((hex) {
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _parseHexColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
                        ),
                      );
                    }).toList(),
                  )
                else
                  const Text(
                    'Nenhuma cor definida.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 24),
                // Filiação a Organizações
                const Text(
                  'Organizações Filiadas (Federações, Associações e Ligas)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                orgsAsync.when(
                  data: (orgs) {
                    if (orgs.isEmpty) {
                      return const Text(
                        'Nenhuma organização cadastrada.',
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    }
                    return Column(
                      children: orgs.map((org) {
                        final selected = _selectedOrgs.contains(org.id);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(org.tradeName),
                          subtitle: Text(org.organizationType?.label ?? ''),
                          value: selected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
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
                  loading: () =>
                      const AppLoading(message: 'Carregando organizações...'),
                  error: (e, _) => Text('Erro ao carregar organizações: $e'),
                ),
                const SizedBox(height: 24),
                KicksterButton(
                  label: isEditing ? 'Salvar alterações' : 'Criar agremiação',
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
}
