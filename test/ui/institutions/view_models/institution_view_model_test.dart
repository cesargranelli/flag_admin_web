import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/ui/institutions/view_models/institution_view_model.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import '../../../../testing/fakes/fake_institution_service.dart';

void main() {
  group('InstitutionViewModel', () {
    late FakeInstitutionService fakeService;
    late InstitutionRepository repository;
    late InstitutionViewModel viewModel;

    final inst1 = createTestInstitution(
      id: 'inst-1',
      name: 'Spartans Flag',
      type: InstitutionType.club,
    );
    final inst2 = createTestInstitution(
      id: 'inst-2',
      name: 'USP Flag',
      type: InstitutionType.university,
    );

    setUp(() {
      fakeService = FakeInstitutionService(
        initial: [inst1, inst2],
      );
      repository = InstitutionRepository(service: fakeService);
      viewModel = InstitutionViewModel(repository: repository);
    });

    test('estado inicial possui coleções vazias e flags desligadas', () {
      expect(viewModel.institutions, isEmpty);
      expect(viewModel.filteredInstitutions, isEmpty);
      expect(viewModel.selectedIds, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.typeFilter, isNull);
    });

    test('load() preenche institutions e gerencia isLoading', () async {
      final listenerNotifications = <bool>[];
      viewModel.addListener(() {
        listenerNotifications.add(viewModel.isLoading);
      });

      await viewModel.load();

      expect(viewModel.institutions.length, 2);
      expect(viewModel.institutions.map((i) => i.id), containsAll(['inst-1', 'inst-2']));
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(listenerNotifications, contains(true));
      expect(listenerNotifications.last, isFalse);
    });

    test('load() captura falhas e define errorMessage', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Erro interno do servidor';

      await viewModel.load();

      expect(viewModel.institutions, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, contains('Erro interno do servidor'));
    });

    test('delete() remove a agremiação e limpa de selectedIds', () async {
      await viewModel.load();
      viewModel.toggleSelection('inst-1');
      expect(viewModel.isSelected('inst-1'), isTrue);

      final success = await viewModel.delete('inst-1');

      expect(success, isTrue);
      expect(viewModel.isSelected('inst-1'), isFalse);
      expect(viewModel.institutions.map((i) => i.id), isNot(contains('inst-1')));
    });

    test('toggleSelection alterna ids corretamente', () {
      expect(viewModel.isSelected('inst-1'), isFalse);

      viewModel.toggleSelection('inst-1');
      expect(viewModel.isSelected('inst-1'), isTrue);
      expect(viewModel.selectedIds, contains('inst-1'));

      viewModel.toggleSelection('inst-1');
      expect(viewModel.isSelected('inst-1'), isFalse);
      expect(viewModel.selectedIds, isEmpty);
    });

    test('selectAll e clearSelection gerenciam seleção em lote', () {
      viewModel.selectAll(['inst-1', 'inst-2']);
      expect(viewModel.selectedIds.length, 2);
      expect(viewModel.isSelected('inst-1'), isTrue);
      expect(viewModel.isSelected('inst-2'), isTrue);

      viewModel.clearSelection();
      expect(viewModel.selectedIds, isEmpty);
    });

    test('filteredInstitutions aplica filtro de busca por nome', () async {
      await viewModel.load();

      viewModel.setSearchQuery('Spartans');
      expect(viewModel.filteredInstitutions.length, 1);
      expect(viewModel.filteredInstitutions.first.id, 'inst-1');

      viewModel.setSearchQuery('usp');
      expect(viewModel.filteredInstitutions.length, 1);
      expect(viewModel.filteredInstitutions.first.id, 'inst-2');

      viewModel.setSearchQuery('inexistente');
      expect(viewModel.filteredInstitutions, isEmpty);
    });

    test('filteredInstitutions aplica filtro por tipo de agremiação', () async {
      await viewModel.load();

      viewModel.setTypeFilter(InstitutionType.club);
      expect(viewModel.filteredInstitutions.length, 1);
      expect(viewModel.filteredInstitutions.first.id, 'inst-1');

      viewModel.setTypeFilter(InstitutionType.university);
      expect(viewModel.filteredInstitutions.length, 1);
      expect(viewModel.filteredInstitutions.first.id, 'inst-2');

      viewModel.setTypeFilter(null);
      expect(viewModel.filteredInstitutions.length, 2);
    });
  });
}
