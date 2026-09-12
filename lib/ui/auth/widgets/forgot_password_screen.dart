import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela de recuperação de senha no visual do kit Kickster (ADR-001 / MVVM 1:1).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = ref.read(forgotPasswordViewModelProvider);
    await vm.sendPasswordReset(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(forgotPasswordViewModelProvider);

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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shadowColor: AppColors.black.withValues(alpha: 0.08),
                  color: AppColors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.line, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                    child: vm.isSent
                        ? _buildSent(context, vm)
                        : _buildForm(context, vm),
                  ),
                ),
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
          // Logo e título no topo do card
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: AppColors.primary, size: 40),
              SizedBox(width: 12),
              Text(
                'Flag Platform',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Esqueci a senha',
            textAlign: TextAlign.center,
            style: AppTextStyles.headline1,
          ),
          const SizedBox(height: 8),
          Text(
            'Recupere a senha da sua conta',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 32),
          if (vm.errorMessage != null) ...[
            _errorBanner(vm.errorMessage!),
            const SizedBox(height: 16),
          ],
          KicksterInput(
            label: AppStrings.loginEmail,
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.loginRequiredEmail;
              }
              if (!value.contains('@')) {
                return AppStrings.loginInvalidEmail;
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          KicksterButton(
            label: 'Enviar e-mail de recuperação',
            onPressed: vm.isLoading ? null : _submit,
            loading: vm.isLoading,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              'Voltar para o login',
              style: AppTextStyles.footerLink.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSent(BuildContext context, dynamic vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo e título no topo do card
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, color: AppColors.primary, size: 40),
            SizedBox(width: 12),
            Text(
              'Flag Platform',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Icon(
          Icons.mark_email_read_outlined,
          color: AppColors.primary,
          size: 64,
        ),
        const SizedBox(height: 24),
        const Text(
          'E-mail enviado!',
          textAlign: TextAlign.center,
          style: AppTextStyles.headline1,
        ),
        const SizedBox(height: 12),
        Text(
          'Se o e-mail informado estiver cadastrado, enviamos as instruções de recuperação para ele. Verifique também a pasta de spam.',
          textAlign: TextAlign.center,
          style: AppTextStyles.paragraph.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        KicksterButton(
          label: 'Voltar para o login',
          onPressed: () {
            vm.reset();
            context.go('/login');
          },
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