/// User domain providers (repository + viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/repositories/user_repository.dart';
import 'package:flag_admin_web/ui/user/view_models/user_list_view_model.dart';
import 'package:flag_admin_web/ui/user/view_models/user_create_view_model.dart';

import 'auth_providers.dart';

/// Repositório de Usuários (ADR-001 - Cache TTL 30s).
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(service: ref.watch(authServiceProvider)),
);

/// ViewModel para a listagem de Usuários (ADR-011 / MVVM).
final userListViewModelProvider =
    ChangeNotifierProvider.autoDispose<UserListViewModel>(
      (ref) => UserListViewModel(repository: ref.watch(userRepositoryProvider)),
    );

/// ViewModel para a criação de um novo Usuário (ADR-011 / MVVM).
final userCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<UserCreateViewModel>(
      (ref) =>
          UserCreateViewModel(repository: ref.watch(userRepositoryProvider)),
    );
