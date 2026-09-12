/// Game domain providers (services, repositories, viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/services/api_game_service.dart';
import 'package:flag_admin_web/data/services/game_service.dart';
import 'package:flag_admin_web/data/repositories/game_repository.dart';
import 'package:flag_admin_web/ui/game/view_models/game_list_view_model.dart';
import 'package:flag_admin_web/ui/game/view_models/game_detail_view_model.dart';
import 'package:flag_admin_web/ui/game/view_models/game_create_view_model.dart';
import 'package:flag_admin_web/ui/game/view_models/game_edit_view_model.dart';

import 'base_providers.dart';

/// Serviço de jogos (REST).
final gameServiceProvider = Provider<GameService>(
  (ref) => ApiGameService(ref.watch(apiClientProvider)),
);

/// Repositório de jogos (Cache TTL 30s).
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => GameRepository(service: ref.watch(gameServiceProvider)),
);

/// ViewModel para a listagem de Jogos (ADR-011 / MVVM).
final gameListViewModelProvider =
    ChangeNotifierProvider.autoDispose<GameListViewModel>(
      (ref) => GameListViewModel(repository: ref.watch(gameRepositoryProvider)),
    );

/// ViewModel para o detalhe de um Jogo (ADR-011 / MVVM).
final gameDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<GameDetailViewModel, String>(
      (ref, gameId) => GameDetailViewModel(repository: ref.watch(gameRepositoryProvider)),
    );

/// ViewModel para a criação de um novo Jogo (ADR-011 / MVVM).
final gameCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<GameCreateViewModel>(
      (ref) => GameCreateViewModel(repository: ref.watch(gameRepositoryProvider)),
    );

/// ViewModel para a edição de um Jogo existente (ADR-011 / MVVM).
final gameEditViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<GameEditViewModel, String>(
      (ref, gameId) => GameEditViewModel(repository: ref.watch(gameRepositoryProvider)),
    );
