import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/repositories/institution_repository.dart';
import 'package:flag_admin_web/domain/models/institution.dart';
import '../../../testing/fakes/fake_institution_service.dart';

void main() {
  group('InstitutionRepository', () {
    late FakeInstitutionService fakeService;
    late InstitutionRepository repository;

    final inst1 = createTestInstitution(id: '1', name: 'Spartans', type: InstitutionType.club);
    final inst2 = createTestInstitution(id: '2', name: 'USP Flag', type: InstitutionType.university);

    setUp(() {
      fakeService = FakeInstitutionService(
        initial: [inst1, inst2],
      );
      repository = InstitutionRepository(service: fakeService);
    });

    test('getInstitutions busca do service e retorna agremiações', () async {
      final result = await repository.getInstitutions();

      expect(result.length, 2);
      expect(result.map((i) => i.id), containsAll(['1', '2']));
      expect(fakeService.getInstitutionsCallCount, 1);
    });

    test('getInstitutions utiliza cache na segunda chamada sem forceRefresh', () async {
      await repository.getInstitutions();
      expect(fakeService.getInstitutionsCallCount, 1);

      final secondCall = await repository.getInstitutions();
      expect(secondCall.length, 2);
      expect(fakeService.getInstitutionsCallCount, 1);
    });

    test('getInstitutions com forceRefresh=true invalida cache e chama service', () async {
      await repository.getInstitutions();
      expect(fakeService.getInstitutionsCallCount, 1);

      await repository.getInstitutions(forceRefresh: true);
      expect(fakeService.getInstitutionsCallCount, 2);
    });

    test('getInstitution retorna do cache se previamente carregado', () async {
      await repository.getInstitutions();

      final found = await repository.getInstitution('1');
      expect(found.name, 'Spartans');
    });

    test('createInstitution chama service e invalida cache', () async {
      await repository.getInstitutions();
      expect(fakeService.getInstitutionsCallCount, 1);

      final created = await repository.createInstitution({
        'name': 'Corinthians Steamrollers',
        'type': 'CLUB',
        'colors': ['#000000', '#FFFFFF'],
        'organizations': <String>[],
      });
      expect(created.name, 'Corinthians Steamrollers');

      final updated = await repository.getInstitutions();
      expect(fakeService.getInstitutionsCallCount, 2);
      expect(updated.map((i) => i.id), contains(created.id));
    });

    test('updateInstitution chama service e invalida cache', () async {
      await repository.getInstitutions();

      final updated = await repository.updateInstitution('1', {
        'name': 'Spartans Updated',
      });
      expect(updated.name, 'Spartans Updated');

      final list = await repository.getInstitutions();
      expect(list.firstWhere((i) => i.id == '1').name, 'Spartans Updated');
    });

    test('deleteInstitution chama service e limpa cache', () async {
      await repository.getInstitutions();
      expect(fakeService.getInstitutionsCallCount, 1);

      await repository.deleteInstitution('1');
      expect(fakeService.deleteCallCount, 1);

      final updated = await repository.getInstitutions();
      expect(fakeService.getInstitutionsCallCount, 2);
      expect(updated.map((i) => i.id), isNot(contains('1')));
    });

    test('updateOrganizations chama service e limpa cache', () async {
      await repository.getInstitutions();

      await repository.updateOrganizations('1', ['org-1', 'org-2']);
      expect(fakeService.updateOrganizationsCallCount, 1);

      final updated = await repository.getInstitution('1');
      expect(updated.organizations, containsAll(['org-1', 'org-2']));
    });

    test('propaga erro quando service falha', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Falha de conexão com backend';

      expect(
        () => repository.getInstitutions(forceRefresh: true),
        throwsA(isA<Exception>()),
      );
    });
  });
}
