import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_view_model.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import '../../../../testing/fakes/fake_organization_service.dart';

void main() {
  group('OrganizationViewModel', () {
    late FakeOrganizationService fakeService;
    late OrganizationRepository repository;
    late OrganizationViewModel viewModel;

    final org1 = createTestOrganization(
      id: 'org-1',
      tradeName: 'Torneio Paulista',
      legalName: 'Federacao Paulista de Flag',
      type: OrganizationType.federation,
    );
    final org2 = createTestOrganization(
      id: 'org-2',
      tradeName: 'Liga Carioca',
      legalName: 'Associacao Carioca de Futebol Americano',
      type: OrganizationType.league,
    );
    final org3Inactive = createTestOrganization(
      id: 'org-3',
      tradeName: 'Liga Mineira',
      legalName: 'Federacao Mineira',
      status: OrganizationStatus.inactive,
      type: OrganizationType.league,
    );

    setUp(() {
      fakeService = FakeOrganizationService(
        initial: [org1, org2, org3Inactive],
      );
      repository = OrganizationRepository(service: fakeService);
      viewModel = OrganizationViewModel(repository: repository);
    });

    test('estado inicial possui coleções vazias e flags desligadas', () {
      expect(viewModel.organizations, isEmpty);
      expect(viewModel.filteredOrganizations, isEmpty);
      expect(viewModel.selectedIds, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.typeFilter, isNull);
      expect(viewModel.showDisabled, isFalse);
    });

    test('load() preenche organizations e gerencia isLoading', () async {
      final listenerNotifications = <bool>[];
      viewModel.addListener(() {
        listenerNotifications.add(viewModel.isLoading);
      });

      await viewModel.load();

      expect(viewModel.organizations.length, 2);
      expect(viewModel.organizations.map((o) => o.id), containsAll(['org-1', 'org-2']));
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      // Deve ter notificado durante loading (true) e ao finalizar (false)
      expect(listenerNotifications, contains(true));
      expect(listenerNotifications.last, isFalse);
    });

    test('load() captura falhas e define errorMessage', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Erro interno do servidor';

      await viewModel.load();

      expect(viewModel.organizations, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, contains('Erro interno do servidor'));
    });

    test('delete() remove a organização e limpa de selectedIds', () async {
      await viewModel.load();
      viewModel.toggleSelection('org-1');
      expect(viewModel.isSelected('org-1'), isTrue);

      final success = await viewModel.delete('org-1');

      expect(success, isTrue);
      expect(viewModel.isSelected('org-1'), isFalse);
      expect(viewModel.organizations.map((o) => o.id), isNot(contains('org-1')));
    });

    test('reactivate() restaura a organização', () async {
      viewModel.setShowDisabled(true);
      await viewModel.load();
      expect(viewModel.organizations.map((o) => o.id), contains('org-3'));

      final success = await viewModel.reactivate('org-3');
      expect(success, isTrue);

      // Agora desativa o toggle de inativos e a org-3 deve aparecer pois foi reativada
      viewModel.setShowDisabled(false);
      await viewModel.load();
      expect(viewModel.organizations.map((o) => o.id), contains('org-3'));
    });

    test('toggleSelection alterna ids corretamente', () {
      expect(viewModel.isSelected('org-1'), isFalse);

      viewModel.toggleSelection('org-1');
      expect(viewModel.isSelected('org-1'), isTrue);
      expect(viewModel.selectedIds, contains('org-1'));

      viewModel.toggleSelection('org-1');
      expect(viewModel.isSelected('org-1'), isFalse);
      expect(viewModel.selectedIds, isEmpty);
    });

    test('selectAll e clearSelection gerenciam seleção em lote', () {
      viewModel.selectAll(['org-1', 'org-2']);
      expect(viewModel.selectedIds.length, 2);
      expect(viewModel.isSelected('org-1'), isTrue);
      expect(viewModel.isSelected('org-2'), isTrue);

      viewModel.clearSelection();
      expect(viewModel.selectedIds, isEmpty);
    });

    test('filteredOrganizations aplica filtro de busca por tradeName e legalName', () async {
      await viewModel.load();

      viewModel.setSearchQuery('Paulista');
      expect(viewModel.filteredOrganizations.length, 1);
      expect(viewModel.filteredOrganizations.first.id, 'org-1');

      viewModel.setSearchQuery('carioca');
      expect(viewModel.filteredOrganizations.length, 1);
      expect(viewModel.filteredOrganizations.first.id, 'org-2');

      viewModel.setSearchQuery('inexistente');
      expect(viewModel.filteredOrganizations, isEmpty);
    });

    test('filteredOrganizations aplica filtro por tipo de organização', () async {
      await viewModel.load();

      viewModel.setTypeFilter(OrganizationType.federation);
      expect(viewModel.filteredOrganizations.length, 1);
      expect(viewModel.filteredOrganizations.first.id, 'org-1');

      viewModel.setTypeFilter(OrganizationType.league);
      expect(viewModel.filteredOrganizations.length, 1);
      expect(viewModel.filteredOrganizations.first.id, 'org-2');

      viewModel.setTypeFilter(null);
      expect(viewModel.filteredOrganizations.length, 2);
    });
  });
}
