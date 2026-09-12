/// Venue domain providers (services, repositories, viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/services/api_venue_service.dart';
import 'package:flag_admin_web/data/services/venue_service.dart';
import 'package:flag_admin_web/data/repositories/venue_repository.dart';
import 'package:flag_admin_web/data/services/storage_service.dart';
import 'package:flag_admin_web/data/api/services/venue_api.dart';
import 'package:flag_admin_web/ui/venue/view_models/venue_list_view_model.dart';
import 'package:flag_admin_web/ui/venue/view_models/venue_detail_view_model.dart';
import 'package:flag_admin_web/ui/venue/view_models/venue_create_view_model.dart';
import 'package:flag_admin_web/ui/venue/view_models/venue_edit_view_model.dart';

import 'base_providers.dart';
import 'package:flag_admin_web/config/domain_imports.dart';

/// Serviço de praças esportivas / venues (REST).
final venueServiceProvider = Provider<VenueService>(
  (ref) => ApiVenueService(ref.watch(apiClientProvider)),
);

/// Repositório de praças esportivas (Cache TTL 60s).
final venueRepositoryProvider = Provider<VenueRepository>(
  (ref) => VenueRepository(service: ref.watch(venueServiceProvider)),
);

/// Serviço de armazenamento (Firebase Storage).
final storageServiceProvider = Provider<StorageService>((ref) {
  return FirebaseStorageService(ref.watch(firebaseStorageProvider));
});

/// Serviço de campos de jogo (REST API).
final venueApiProvider = Provider<VenueApi>(
  (ref) => VenueApi(ref.watch(apiClientProvider)),
);

/// Listagem de campos de jogo da tela de gestão.
final venuesProvider = FutureProvider<List<Venue>>(
  (ref) => ref.watch(venueApiProvider).list(),
);

/// ViewModel para a listagem de Venues (ADR-011 / MVVM).
final venueListViewModelProvider = ChangeNotifierProvider<VenueListViewModel>(
  (ref) => VenueListViewModel(repository: ref.watch(venueRepositoryProvider)),
);

/// ViewModel para o detalhe de um Venue (ADR-011 / MVVM).
final venueDetailViewModelProvider =
    ChangeNotifierProvider.family<VenueDetailViewModel, String>(
      (ref, venueId) => VenueDetailViewModel(repository: ref.watch(venueRepositoryProvider)),
    );

/// ViewModel para a criação de um novo Venue (ADR-011 / MVVM).
final venueCreateViewModelProvider =
    ChangeNotifierProvider<VenueCreateViewModel>(
      (ref) => VenueCreateViewModel(repository: ref.watch(venueRepositoryProvider)),
    );

/// ViewModel para a edição de um Venue existente (ADR-011 / MVVM).
final venueEditViewModelProvider =
    ChangeNotifierProvider.family<VenueEditViewModel, String>(
      (ref, venueId) => VenueEditViewModel(repository: ref.watch(venueRepositoryProvider)),
    );

/// Detalhe de um campo por id.
final venueProvider = FutureProvider.autoDispose.family<Venue, String>(
  (ref, id) => ref.watch(venueApiProvider).getById(id),
);
