/// Round domain providers (services, repositories, viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/services/api_round_service.dart';
import 'package:flag_admin_web/data/services/round_service.dart';
import 'package:flag_admin_web/data/repositories/round_repository.dart';
import 'package:flag_admin_web/ui/round/view_models/round_list_view_model.dart';
import 'package:flag_admin_web/ui/round/view_models/round_detail_view_model.dart';
import 'package:flag_admin_web/ui/round/view_models/round_create_view_model.dart';
import 'package:flag_admin_web/ui/round/view_models/round_edit_view_model.dart';

import 'base_providers.dart';

/// Serviço de rodadas (REST).
final roundServiceProvider = Provider<RoundService>(
  (ref) => ApiRoundService(ref.watch(apiClientProvider)),
);

/// Repositório de rodadas (Cache TTL 30s).
final roundRepositoryProvider = Provider<RoundRepository>(
  (ref) => RoundRepository(service: ref.watch(roundServiceProvider)),
);

/// ViewModel para a listagem de Rodadas (ADR-011 / MVVM).
final roundListViewModelProvider =
    ChangeNotifierProvider.autoDispose<RoundListViewModel>(
      (ref) => RoundListViewModel(repository: ref.watch(roundRepositoryProvider)),
    );

/// ViewModel para o detalhe de uma Rodada (ADR-011 / MVVM).
final roundDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<RoundDetailViewModel, String>(
      (ref, roundId) => RoundDetailViewModel(repository: ref.watch(roundRepositoryProvider)),
    );

/// ViewModel para a criação de uma nova Rodada (ADR-011 / MVVM).
final roundCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<RoundCreateViewModel>(
      (ref) => RoundCreateViewModel(repository: ref.watch(roundRepositoryProvider)),
    );

/// ViewModel para a edição de uma Rodada existente (ADR-011 / MVVM).
final roundEditViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<RoundEditViewModel, String>(
      (ref, roundId) => RoundEditViewModel(repository: ref.watch(roundRepositoryProvider)),
    );

/// Rodada selecionada na tela de jogos.
final selectedRoundProvider = StateProvider<String?>((ref) => null);
