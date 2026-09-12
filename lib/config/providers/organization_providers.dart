/// Organization domain providers (services, repositories, viewmodels).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/data/services/organization_service.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/domain/models/affiliation_window.dart';
import 'package:flag_admin_web/domain/models/organization.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_detail_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_create_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_edit_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_affiliates_view_model.dart';
import 'package:flag_admin_web/ui/organization/view_models/associate_clubs_view_model.dart';

import 'base_providers.dart';

/// Serviço de organizações (REST).
final organizationServiceProvider = Provider<OrganizationService>(
  (ref) => OrganizationService(ref.watch(apiClientProvider)),
);

/// Repository de organizações (Single Source of Truth, Caching).
final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) =>
      OrganizationRepository(service: ref.watch(organizationServiceProvider)),
);

/// ViewModel de organizações (UI State e Commands).
final organizationViewModelProvider =
    ChangeNotifierProvider<OrganizationViewModel>(
      (ref) => OrganizationViewModel(
        repository: ref.watch(organizationRepositoryProvider),
      ),
    );

/// ViewModel de detalhes de organização.
final organizationDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<OrganizationDetailViewModel, String>(
      (ref, id) => OrganizationDetailViewModel(
        repository: ref.watch(organizationRepositoryProvider),
        organizationId: id,
      ),
    );

/// Lista de janelas de filiação abertas no momento (para qualquer organização).
final openAffiliationWindowsProvider =
    FutureProvider.autoDispose<List<AffiliationWindow>>(
      (ref) =>
          ref.watch(organizationRepositoryProvider).getOpenAffiliationWindows(),
    );

/// ViewModel dedicada para a tela de Consulta de Agremiações Filiadas (ADR-001 / MVVM 1:1).
final organizationAffiliatesViewModelProvider = ChangeNotifierProvider
    .autoDispose
    .family<OrganizationAffiliatesViewModel, String>(
      (ref, id) => OrganizationAffiliatesViewModel(
        repository: ref.watch(organizationRepositoryProvider),
        organizationId: id,
      ),
    );

/// ViewModel dedicada para a tela de Criação de Organização (ADR-001 / MVVM 1:1).
final organizationCreateViewModelProvider =
    ChangeNotifierProvider.autoDispose<OrganizationCreateViewModel>(
      (ref) => OrganizationCreateViewModel(
        repository: ref.watch(organizationRepositoryProvider),
      ),
    );

/// ViewModel dedicada para a tela de Edição de Organização (ADR-001 / MVVM 1:1).
final organizationEditViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<OrganizationEditViewModel, String>(
      (ref, id) => OrganizationEditViewModel(
        repository: ref.watch(organizationRepositoryProvider),
        organizationId: id,
      ),
    );

/// ViewModel de associação de clubes.
final associateClubsViewModelProvider =
    ChangeNotifierProvider.autoDispose<AssociateClubsViewModel>(
      (ref) => AssociateClubsViewModel(),
    );

/// Listagem de organizações da tela de gestão.
final organizationsProvider = FutureProvider<List<Organization>>(
  (ref) => ref.watch(organizationRepositoryProvider).getOrganizations(),
);

/// Detalhe de uma organização por id.
final organizationProvider = FutureProvider.autoDispose
    .family<Organization, String>(
      (ref, id) =>
          ref.watch(organizationRepositoryProvider).getOrganization(id),
    );
