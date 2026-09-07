import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/ui/organization/view_models/organization_detail_view_model.dart';
import '../../../../testing/fakes/fake_organization_service.dart';

void main() {
  group('OrganizationDetailViewModel', () {
    late FakeOrganizationService fakeService;
    late OrganizationRepository repository;

    final org = createTestOrganization(
      id: 'org-10',
      tradeName: 'Spartans Flag',
      legalName: 'Spartans Flag Football',
    );

    setUp(() {
      fakeService = FakeOrganizationService(initial: [org]);
      repository = OrganizationRepository(service: fakeService);
    });

    test('inicializa com initialOrganization sem necessidade de load()', () {
      final vm = OrganizationDetailViewModel(
        repository: repository,
        organizationId: 'org-10',
        initialOrganization: org,
      );

      expect(vm.organization, equals(org));
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('load() busca do repositório quando não tem initialOrganization', () async {
      final vm = OrganizationDetailViewModel(
        repository: repository,
        organizationId: 'org-10',
      );

      expect(vm.organization, isNull);

      await vm.load();

      expect(vm.organization?.id, 'org-10');
      expect(vm.organization?.tradeName, 'Spartans Flag');
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('load() define errorMessage quando falha', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Erro 404: Organização não existe';

      final vm = OrganizationDetailViewModel(
        repository: repository,
        organizationId: 'org-99',
      );

      await vm.load();

      expect(vm.organization, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, contains('404'));
    });
  });
}
