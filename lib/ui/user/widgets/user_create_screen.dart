import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/domain_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/ui/user/view_models/user_create_view_model.dart'
    as vm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulário de criação de usuário (somente ADMIN).
class UserCreateScreen extends ConsumerStatefulWidget {
  const UserCreateScreen({super.key});

  @override
  ConsumerState<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends ConsumerState<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _email;
  late vm.UserCreateViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _email = TextEditingController();
    _viewModel = ref.read(userCreateViewModelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.init();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _viewModel.save();
    if (success && mounted) {
      context.pop();
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value.trim()) ? null : 'E-mail inválido';
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Novo usuário',
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.users, route: '/users'),
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
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KicksterInput(
                          label: 'Nome',
                          controller: _name,
                          maxLength: 100,
                          onChanged: (value) => _viewModel.setName(value),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Informe o nome'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        KicksterInput(
                          label: 'E-mail',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => _viewModel.setEmail(value),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        KicksterDropdown<String>(
                          label: 'Papel',
                          helperText: 'Mesa: opera partidas ao vivo',
                          value: _viewModel.role,
                          items: UserRole.values
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.label,
                                  child: Text(r.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => _viewModel.setRole(value),
                        ),
                        if (_viewModel.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _viewModel.errorMessage!,
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                              loading: _viewModel.isSubmitting,
                              onPressed: _viewModel.isSubmitting ? null : _save,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
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
