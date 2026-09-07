import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela de cadastro de organizador no visual do kit Kickster (ADR-001 / MVVM 1:1).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = ref.read(signupViewModelProvider);
    await vm.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(signupViewModelProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceMuted, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: vm.isSuccess ? _buildSuccess(context) : _buildForm(context, vm),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, dynamic vm) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.errorMessage != null) ...[
            _errorBanner(vm.errorMessage!),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          // Marca compacta no topo
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Flag Platform',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Crie sua conta',
            textAlign: TextAlign.center,
            style: AppTextStyles.headline1,
          ),
          const SizedBox(height: 8),
          Text(
            'Acesso para organizadores de competição',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 32),
          KicksterInput(
            label: 'Nome completo',
            controller: _nameController,
            autofocus: true,
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu nome completo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          KicksterInput(
            label: AppStrings.loginEmail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            autofillHints: const [
              AutofillHints.username,
              AutofillHints.email,
            ],
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.loginRequiredEmail;
              }
              if (!value.contains('@')) {
                return AppStrings.loginInvalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          KicksterInput(
            label: AppStrings.loginPassword,
            controller: _passwordController,
            obscureText: vm.obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              tooltip: vm.obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              icon: Icon(vm.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: vm.toggleObscurePassword,
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.loginRequiredPassword;
              }
              if (value.length < 6) {
                return 'A senha deve ter no mínimo 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          KicksterInput(
            label: 'Confirmar senha',
            controller: _confirmController,
            obscureText: vm.obscureConfirm,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              tooltip: vm.obscureConfirm ? 'Mostrar confirmação' : 'Ocultar confirmação',
              icon: Icon(vm.obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: vm.toggleObscureConfirm,
            ),
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirme sua senha';
              }
              if (value != _passwordController.text) {
                return 'As senhas não conferem';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          KicksterButton(
            label: 'Cadastrar',
            onPressed: vm.isLoading ? null : _submit,
            loading: vm.isLoading,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              const Text(
                'Já tem conta?',
                style: AppTextStyles.footerLink,
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Acessar conta',
                  style: AppTextStyles.footerLink.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.success,
          size: 64,
        ),
        const SizedBox(height: 24),
        const Text(
          'Conta solicitada!',
          textAlign: TextAlign.center,
          style: AppTextStyles.headline1,
        ),
        const SizedBox(height: 12),
        Text(
          'Seu cadastro foi enviado com sucesso. Como medida de segurança, o acesso de organizador precisa ser aprovado por um administrador da plataforma antes de você começar a usar o sistema.',
          textAlign: TextAlign.center,
          style: AppTextStyles.paragraph.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        KicksterButton(
          label: 'Voltar para o login',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.paragraph.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
