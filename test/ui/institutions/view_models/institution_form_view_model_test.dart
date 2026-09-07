import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/ui/institutions/view_models/institution_form_view_model.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import '../../../../testing/fakes/fake_institution_service.dart';

void main() {
  group('InstitutionFormViewModel', () {
    late FakeInstitutionService fakeService;
    late InstitutionRepository repository;
    late InstitutionFormViewModel viewModel;

    setUp(() {
      fakeService = FakeInstitutionService();
      repository = InstitutionRepository(service: fakeService);
      viewModel = InstitutionFormViewModel(repository: repository);
    });

    test('estado inicial possui isSubmitting falso e erros nulos', () {
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.savedInstitution, isNull);
    });

    test('save() cria nova agremiação quando id é nulo e atualiza filiações', () async {
      final success = await viewModel.save(
        name: 'Spartans Flag',
        type: InstitutionType.club,
        colors: ['#000000', '#FF0000'],
        organizationIds: ['org-1', 'org-2'],
      );

      expect(success, isTrue);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.savedInstitution, isNotNull);
      expect(viewModel.savedInstitution?.name, 'Spartans Flag');
      expect(viewModel.savedInstitution?.type, InstitutionType.club);
      expect(viewModel.errorMessage, isNull);
      expect(fakeService.institutions.length, 1);
      expect(fakeService.updateOrganizationsCallCount, 1);
      expect(fakeService.institutions.first.organizations, containsAll(['org-1', 'org-2']));
    });

    test('save() atualiza agremiação existente quando id é fornecido', () async {
      final existing = createTestInstitution(
        id: 'inst-1',
        name: 'Nome Antigo',
        type: InstitutionType.club,
      );
      fakeService.institutions.add(existing);

      final success = await viewModel.save(
        id: 'inst-1',
        name: 'Nome Atualizado',
        type: InstitutionType.university,
        colors: ['#0000FF'],
        organizationIds: ['org-3'],
      );

      expect(success, isTrue);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.savedInstitution, isNotNull);
      expect(viewModel.savedInstitution?.name, 'Nome Atualizado');
      expect(viewModel.savedInstitution?.type, InstitutionType.university);
      expect(viewModel.errorMessage, isNull);
      expect(fakeService.institutions.first.organizations, contains('org-3'));
    });

    test('save() trata exceção e define errorMessage', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Erro ao salvar agremiação no backend';

      final success = await viewModel.save(
        name: 'Clube Falha',
        type: InstitutionType.club,
        colors: [],
        organizationIds: [],
      );

      expect(success, isFalse);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.savedInstitution, isNull);
      expect(viewModel.errorMessage, contains('Erro ao salvar agremiação no backend'));
    });

    test('reset() restaura estado limpo', () async {
      fakeService.shouldThrow = true;
      await viewModel.save(
        name: 'Teste',
        type: InstitutionType.club,
        colors: [],
        organizationIds: [],
      );
      expect(viewModel.errorMessage, isNotNull);

      viewModel.reset();
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.savedInstitution, isNull);
    });
  });
}
