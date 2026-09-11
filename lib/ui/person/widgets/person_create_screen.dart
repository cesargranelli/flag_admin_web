import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulario de criacao de pessoa (ADR-011 / MVVM 1:1).
///
/// Segue o padrao UX estabelecido: sections, PopScope, dirty tracking,
/// error banner, SnackBar de sucesso e botao cancelar.
class PersonCreateScreen extends ConsumerStatefulWidget {
  const PersonCreateScreen({super.key});

  @override
  ConsumerState<PersonCreateScreen> createState() => _PersonCreateScreenState();
}

class _PersonCreateScreenState extends ConsumerState<PersonCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _cpf;
  late final TextEditingController _photoUrl;
  late final TextEditingController _city;
  String _role = 'athlete';
  String _gender = '';
  DateTime? _birthDate;

  bool _saved = false;
  bool _hasChanges = false;
  String? _errorMessage;

  static const _roleOptions = <String, String>{
    'ATHLETE': 'Atleta',
    'COACH': 'Técnico',
    'TECHNICAL_STAFF': 'Comissão Técnica',
    'REFEREE': 'Árbitro',
    'DELEGATE': 'Delegado',
    'COMMISSIONER': 'Comissário',
  };

  static const _genderOptions = <String, String>{
    '': 'Nao informado',
    'M': 'Masculino',
    'F': 'Feminino',
    'O': 'Outro',
  };

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _cpf = TextEditingController();
    _photoUrl = TextEditingController();
    _city = TextEditingController();

    for (final controller in [_name, _cpf, _photoUrl, _city]) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (_saved || _hasChanges) return;
    setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    for (final controller in [_name, _cpf, _photoUrl, _city]) {
      controller.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validacoes
  // ---------------------------------------------------------------------------

  String? _validateCpf(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DocumentUtils.isValidCpf(value) ? null : 'CPF invalido';
  }

  String? _validatePhotoUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Informe uma URL valida (http/https)';
  }

  // ---------------------------------------------------------------------------
  // Helpers de UI (padrao Organization/Institution)
  // ---------------------------------------------------------------------------

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

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    int? maxLength,
  }) {
    return KicksterInput(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      hintText: hint,
      validator: validator,
      onChanged: onChanged,
      maxLength: maxLength,
    );
  }

  // ---------------------------------------------------------------------------
  // Data de nascimento
  // ---------------------------------------------------------------------------

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
      _markDirty();
    }
  }

  // ---------------------------------------------------------------------------
  // Salvar / Voltar
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final vm = ref.read(personCreateViewModelProvider);
    final ok = await vm.create(
      name: _name.text.trim(),
      cpf: _cpf.text.trim(),
      photoUrl: _photoUrl.text.trim(),
      birthDate: _birthDate,
      gender: _gender.isEmpty ? null : _gender,
      city: _city.text.trim(),
      role: _role,
    );

    if (!mounted) return;

    if (ok) {
      _saved = true;
      ref.invalidate(personsProvider);
      ref.read(personViewModelProvider).load(forceRefresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pessoa cadastrada com sucesso')),
      );
      context.go('/persons');
    } else {
      setState(() {
        _errorMessage =
            vm.errorMessage ?? 'Nao foi possivel cadastrar a pessoa.';
      });
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/persons');
    }
  }

  Future<void> _handleBack() async {
    final isSubmitting = ref.read(personCreateViewModelProvider).isSubmitting;
    if (_hasChanges && !isSubmitting && !_saved) {
      final discard = await showKicksterConfirm(
        context: context,
        title: 'Descartar alteracoes?',
        content: 'As alteracoes nao salvas serao perdidas.',
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(personCreateViewModelProvider).isSubmitting;

    return PopScope(
      canPop: !_hasChanges || isSubmitting || _saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AppScreen(
        title: 'Nova pessoa',
        breadcrumb: const [
          BreadcrumbItem(AppStrings.home, route: '/'),
          BreadcrumbItem('Pessoas', route: '/persons'),
          BreadcrumbItem('Nova'),
        ],
        body: AppLayout.form(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) _errorBanner(_errorMessage!),
                _section('Dados pessoais', Icons.person_outline, [
                  _field(
                    'Nome',
                    _name,
                    hint: 'Informe o nome completo',
                    maxLength: 100,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'CPF',
                    _cpf,
                    keyboardType: TextInputType.number,
                    hint: '000.000.000-00',
                    onChanged: (value) {
                      final masked = DocumentUtils.maskCpf(value);
                      if (masked != value) {
                        _cpf.value = TextEditingValue(
                          text: masked,
                          selection: TextSelection.collapsed(
                            offset: masked.length,
                          ),
                        );
                      }
                    },
                    validator: _validateCpf,
                  ),
                ]),
                _section('Funcao e dados complementares', Icons.badge_outlined, [
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: kicksterFieldDecoration(labelText: 'Funcao'),
                    items: _roleOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _role = value);
                        _markDirty();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: kicksterFieldDecoration(labelText: 'Genero'),
                    items: _genderOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _gender = value);
                        _markDirty();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickBirthDate,
                    child: InputDecorator(
                      decoration: kicksterFieldDecoration(
                        labelText: 'Data de nascimento',
                      ),
                      child: Text(
                        _birthDate != null
                            ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                            : 'Selecionar data',
                        style: TextStyle(
                          color: _birthDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field('Cidade', _city, hint: 'Ex.: Sao Paulo'),
                ]),
                _section('Foto', Icons.photo_camera_outlined, [
                  _field(
                    'URL da foto (opcional)',
                    _photoUrl,
                    keyboardType: TextInputType.url,
                    hint: 'Ex.: https://...',
                    validator: _validatePhotoUrl,
                  ),
                ]),
                const SizedBox(height: 8),
                KicksterButton(
                  label: 'Cadastrar pessoa',
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
