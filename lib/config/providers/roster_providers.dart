/// Roster domain providers (services, repositories, viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/services/roster_service.dart';
import 'package:flag_admin_web/data/repositories/roster_repository.dart';
import 'package:flag_admin_web/ui/person/view_models/roster_view_model.dart';
import 'package:flag_admin_web/ui/person/view_models/roster_import_view_model.dart';

import 'base_providers.dart';
import 'package:flag_admin_web/config/domain_imports.dart';
import 'person_providers.dart';

/// Serviço de elencos (REST).
final rosterServiceProvider = Provider<RosterService>(
  (ref) => ApiRosterService(ref.watch(apiClientProvider)),
);

/// Repositório de elencos (Cache TTL 30s).
final rosterRepositoryProvider = Provider<RosterRepository>(
  (ref) => RosterRepository(service: ref.watch(rosterServiceProvider)),
);

/// Tempo selecionado na tela de elencos.
final selectedTeamProvider = StateProvider<String?>((ref) => null);

/// Elenco de um time (compatibilidade com telas legadas).
final rosterProvider = FutureProvider.autoDispose
    .family<List<RosterEntry>, String>(
      (ref, teamId) => ref.watch(rosterRepositoryProvider).getRoster(teamId),
    );

/// ViewModel de elenco (ADR-011 / MVVM 1:1).
final rosterViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<RosterViewModel, String>(
      (ref, teamId) => RosterViewModel(
        rosterRepository: ref.watch(rosterRepositoryProvider),
        personRepository: ref.watch(personRepositoryProvider),
        teamId: teamId,
      ),
    );

/// ViewModel para a importação de elenco (ADR-011 / MVVM).
final rosterImportViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<RosterImportViewModel, String>(
      (ref, teamId) => RosterImportViewModel(
        rosterRepository: ref.watch(rosterRepositoryProvider),
        personRepository: ref.watch(personRepositoryProvider),
        teamId: teamId,
      ),
    );
