import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/ui/institutions/view_models/institution_detail_view_model.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import '../../../../testing/fakes/fake_institution_service.dart';

void main() {
  group('InstitutionDetailViewModel', () {
    late FakeInstitutionService fakeService;
    late InstitutionRepository repository;

    final inst = createTestInstitution(
      id: 'inst-10',
      name: 'Spartans Flag',
      type: InstitutionType.club,
    );

    setUp(() {
      fakeService = FakeInstitutionService(initial: [inst]);
      repository = InstitutionRepository(service: fakeService);
    });

    test('inicializa com initialInstitution sem necessidade de load()', () {
      final vm = InstitutionDetailViewModel(
        repository: repository,
        institutionId: 'inst-10',
        initialInstitution: inst,
      );

      expect(vm.institution, equals(inst));
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('load() busca do repositório quando não tem initialInstitution', () async {
      final vm = InstitutionDetailViewModel(
        repository: repository,
        institutionId: 'inst-10',
      );

      expect(vm.institution, isNull);

      await vm.load();

      expect(vm.institution?.id, 'inst-10');
      expect(vm.institution?.name, 'Spartans Flag');
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('load() define errorMessage quando falha', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Erro 404: Agremiação não existe';

      final vm = InstitutionDetailViewModel(
        repository: repository,
        institutionId: 'inst-99',
      );

      await vm.load();

      expect(vm.institution, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, contains('404'));
    });
  });
}
