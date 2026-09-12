/// Auth-related providers (session, API client, auth service/repository/controller + viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flag_admin_web/data/api/api.dart';
import 'package:flag_admin_web/data/services/auth_service.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/data/repositories/auth_controller.dart';
import 'package:flag_admin_web/routing/app_router.dart';
import 'package:flag_admin_web/ui/auth/view_models/login_view_model.dart';
import 'package:flag_admin_web/ui/auth/view_models/signup_view_model.dart';
import 'package:flag_admin_web/ui/auth/view_models/forgot_password_view_model.dart';
import 'package:flag_admin_web/ui/home/view_models/home_view_model.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

import 'base_providers.dart';

/// Serviço de autenticação Firebase e REST (ADR-001).
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiClientProvider)),
);

/// Repositório de autenticação (ADR-001 / Single Source of Truth).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    service: ref.watch(authServiceProvider),
    session: ref.watch(sessionManagerProvider),
  );
});

/// Controlador de autenticação (restaura a sessão ao iniciar).
final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    repository: ref.watch(authRepositoryProvider),
  );
  controller.restore();
  return controller;
});

/// ViewModel para a tela de Login (ADR-001 / MVVM 1:1).
final loginViewModelProvider =
    ChangeNotifierProvider.autoDispose<LoginViewModel>((ref) {
      return LoginViewModel(
        repository: ref.watch(authRepositoryProvider),
        onAuthStateChanged: () =>
            ref.read(authControllerProvider).syncFromRepository(),
      );
    });

/// ViewModel para a tela de Cadastro (ADR-001 / MVVM 1:1).
final signupViewModelProvider =
    ChangeNotifierProvider.autoDispose<SignupViewModel>((ref) {
      return SignupViewModel(repository: ref.watch(authRepositoryProvider));
    });

/// ViewModel para a tela de Esqueci a Senha (ADR-001 / MVVM 1:1).
final forgotPasswordViewModelProvider =
    ChangeNotifierProvider.autoDispose<ForgotPasswordViewModel>((ref) {
      return ForgotPasswordViewModel(
        repository: ref.watch(authRepositoryProvider),
      );
    });

/// Serviço de autenticação REST legado (compatibilidade com approvals_screen).
final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

/// Lista de usuários (somente ADMIN).
final usersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(authApiProvider).listUsers(),
);

/// Contas pendentes de aprovação (somente ADMIN).
final pendingUsersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(authApiProvider).listPendingUsers(),
);

/// Router com proteção de rotas.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  return AppRouter.build(auth);
});

/// ViewModel para a tela Inicial / Home (ADR-001 / MVVM 1:1).
final homeViewModelProvider = ChangeNotifierProvider.autoDispose<HomeViewModel>(
  (ref) {
    return HomeViewModel(authRepository: ref.watch(authRepositoryProvider));
  },
);
