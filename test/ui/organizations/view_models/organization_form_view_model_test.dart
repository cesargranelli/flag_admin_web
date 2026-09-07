import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/ui/organizations/view_models/organization_form_view_model.dart';
import '../../../../testing/fakes/fake_organization_service.dart';

void main() {
  group('OrganizationFormViewModel', () {
    late FakeOrganizationService fakeService;
    late OrganizationRepository repository;
    late OrganizationFormViewModel viewModel;

    setUp(() {
      fakeService = FakeOrganizationService();
      repository = OrganizationRepository(service: fakeService);
      viewModel = OrganizationFormViewModel(repository: repository);
    });

    test('estado inicial possui isSubmitting falso e erros nulos', () {
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.createdOrganization, isNull);
    });

    test('createOrganization cria com sucesso e atualiza createdOrganization', () async {
      final success = await viewModel.createOrganization({
        'tradeName': 'Novo Clube',
        'legalName': 'Novo Clube Esportivo',
        'country': 'BR',
        'timezone': 'America/Sao_Paulo',
        'locale': 'pt-BR',
      });

      expect(success, isTrue);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.createdOrganization, isNotNull);
      expect(viewModel.createdOrganization?.tradeName, 'Novo Clube');
      expect(viewModel.errorMessage, isNull);
    });

    test('createOrganization trata exceção e define errorMessage', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'CNPJ já cadastrado';

      final success = await viewModel.createOrganization({
        'tradeName': 'Clube Duplicado',
      });

      expect(success, isFalse);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.createdOrganization, isNull);
      expect(viewModel.errorMessage, contains('CNPJ já cadastrado'));
    });

    test('reset restaura estado limpo', () async {
      fakeService.shouldThrow = true;
      await viewModel.createOrganization({'tradeName': 'Teste'});
      expect(viewModel.errorMessage, isNotNull);

      viewModel.reset();
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isSubmitting, isFalse);
      expect(viewModel.createdOrganization, isNull);
    });
  });
}
