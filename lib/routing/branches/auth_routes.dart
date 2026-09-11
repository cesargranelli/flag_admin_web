import 'package:flag_admin_web/ui/auth/widgets/forgot_password_screen.dart';
import 'package:flag_admin_web/ui/auth/widgets/login_screen.dart';
import 'package:flag_admin_web/ui/auth/widgets/signup_screen.dart';
import 'package:go_router/go_router.dart';

/// Rotas públicas fora da shell.
import 'package:flag_admin_web/src/core/core.dart';
import 'package:flutter/material.dart';

final authRoutes = <GoRoute>[
  GoRoute(path: '/boot', name: 'boot', builder: (c, s) => const _BootScreen()),
  GoRoute(path: '/login', name: 'login', builder: (c, s) => const LoginScreen()),
  GoRoute(path: '/signup', name: 'signup', builder: (c, s) => const SignupScreen()),
  GoRoute(path: '/forgot-password', name: 'forgotPassword', builder: (c, s) => const ForgotPasswordScreen()),
];

class _BootScreen extends StatelessWidget {
  const _BootScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: AppLoading(message: 'Restaurando sessão...'));
}
