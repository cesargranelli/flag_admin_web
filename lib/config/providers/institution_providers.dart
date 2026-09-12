/// Institution domain providers (services, repositories, viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/services/institution_service.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_view_model.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_detail_view_model.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_create_view_model.dart';
import 'package:flag_admin_web/ui/institution/view_models/institution_edit_view_model.dart';

import 'base_providers.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

/// Serviço de agremiações (REST).
final institutionServiceProvider = Provider<InstitutionService>(
  (ref) => ApiInstitutionService(ref.watch(apiClientProvider)),
);

/// Repository de agremiações (Single Source of Truth, Caching).
final institutionRepositoryProvider = Provider<InstitutionRepository>(
  (ref) =>
      InstitutionRepository(service: ref.watch(institutionServiceProvider)),
);

/// ViewModel de agremiações (UI State e Commands).
final institutionViewModelProvider =
    ChangeNotifierProvider<InstitutionViewModel>(
      (ref) => InstitutionViewModel(
        repository: ref.watch(institutionRepositoryProvider),
      ),
    );

/// ViewModel de detalhes de agremiação.
final institutionDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<InstitutionDetailViewModel, String>(
      (ref, id) => InstitutionDetailViewModel(
        repository: ref.watch(institutionRepositoryProvider),
        institutionId: id,
      ),
    );

/// ViewModel dedicada ao CADASTRO de agremiação (1:1 com InstitutionCreateScreen).
final institutionCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<InstitutionCreateViewModel>(
      (ref) => InstitutionCreateViewModel(
        repository: ref.watch(institutionRepositoryProvider),
      ),
    );

/// ViewModel dedicada à EDIÇÃO de agremiação (1:1 com InstitutionEditScreen).
final institutionEditViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<InstitutionEditViewModel, String>(
      (ref, id) => InstitutionEditViewModel(
        repository: ref.watch(institutionRepositoryProvider),
        institutionId: id,
      ),
    );

/// Listagem de agremiações da tela de gestão.
final institutionsProvider = FutureProvider<List<Institution>>(
  (ref) => ref.watch(institutionRepositoryProvider).getInstitutions(),
);

/// Listagem para ADMIN: inclui desativadas quando [includeDisabled].
final institutionsAdminProvider =
    FutureProvider.family<List<Institution>, bool>(
      (ref, includeDisabled) => ref
          .watch(institutionRepositoryProvider)
          .getInstitutions(forceRefresh: false),
    );

/// Detalhe de uma agremiação por id.
final institutionProvider = FutureProvider.autoDispose
    .family<Institution, String>(
      (ref, id) => ref.watch(institutionRepositoryProvider).getInstitution(id),
    );
