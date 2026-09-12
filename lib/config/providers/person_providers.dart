/// Person domain providers (services, repositories, viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/services/person_service.dart';
import 'package:flag_admin_web/data/repositories/person_repository.dart';
import 'package:flag_admin_web/ui/person/view_models/person_view_model.dart';
import 'package:flag_admin_web/ui/person/view_models/person_detail_view_model.dart';
import 'package:flag_admin_web/ui/person/view_models/person_create_view_model.dart';
import 'package:flag_admin_web/ui/person/view_models/person_edit_view_model.dart';

import 'base_providers.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

/// Servico de pessoas (REST).
final personServiceProvider = Provider<PersonService>(
  (ref) => ApiPersonService(ref.watch(apiClientProvider)),
);

/// Repositorio de pessoas (Cache TTL 30s).
final personRepositoryProvider = Provider<PersonRepository>(
  (ref) => PersonRepository(service: ref.watch(personServiceProvider)),
);

/// Lista de pessoas (compatibilidade com telas legadas).
final personsProvider = FutureProvider<List<Person>>(
  (ref) => ref.watch(personRepositoryProvider).getPersons(),
);

/// Detalhe de uma pessoa por id (compatibilidade com telas legadas).
final personProvider = FutureProvider.autoDispose.family<Person, String>(
  (ref, id) => ref.watch(personRepositoryProvider).getPerson(id),
);

/// ViewModel de listagem de pessoas (ADR-011 / MVVM 1:1).
final personViewModelProvider = ChangeNotifierProvider<PersonViewModel>(
  (ref) => PersonViewModel(repository: ref.watch(personRepositoryProvider)),
);

/// ViewModel de detalhes de pessoa (ADR-011 / MVVM 1:1).
final personDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<PersonDetailViewModel, String>(
      (ref, id) => PersonDetailViewModel(
        repository: ref.watch(personRepositoryProvider),
        personId: id,
      ),
    );

/// ViewModel de cadastro de pessoa (ADR-011 / MVVM 1:1).
final personCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<PersonCreateViewModel>(
      (ref) => PersonCreateViewModel(
        repository: ref.watch(personRepositoryProvider),
      ),
    );

/// ViewModel de edicao de pessoa (ADR-011 / MVVM 1:1).
final personEditViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<PersonEditViewModel, String>(
      (ref, id) => PersonEditViewModel(
        repository: ref.watch(personRepositoryProvider),
        personId: id,
      ),
    );
