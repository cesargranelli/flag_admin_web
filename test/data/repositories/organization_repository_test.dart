import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/data/repositories/organization_repository.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import '../../../testing/fakes/fake_organization_service.dart';

void main() {
  group('OrganizationRepository', () {
    late FakeOrganizationService fakeService;
    late OrganizationRepository repository;

    final org1 = createTestOrganization(id: '1', tradeName: 'Liga Nacional');
    final org2 = createTestOrganization(id: '2', tradeName: 'Federação SP');
    final orgDisabled = createTestOrganization(
      id: '3',
      tradeName: 'Liga Inativa',
      status: OrganizationStatus.inactive,
    );

    setUp(() {
      fakeService = FakeOrganizationService(
        initial: [org1, org2, orgDisabled],
      );
      repository = OrganizationRepository(service: fakeService);
    });

    test('getOrganizations busca do service e retorna apenas ativas por padrão', () async {
      final result = await repository.getOrganizations();

      expect(result.length, 2);
      expect(result.map((o) => o.id), containsAll(['1', '2']));
      expect(fakeService.getOrganizationsCallCount, 1);
    });

    test('getOrganizations utiliza cache na segunda chamada sem forceRefresh', () async {
      await repository.getOrganizations();
      expect(fakeService.getOrganizationsCallCount, 1);

      final secondCall = await repository.getOrganizations();
      expect(secondCall.length, 2);
      expect(fakeService.getOrganizationsCallCount, 1); // Continua 1 (cache hit)
    });

    test('getOrganizations com forceRefresh=true invalida cache e chama service', () async {
      await repository.getOrganizations();
      expect(fakeService.getOrganizationsCallCount, 1);

      await repository.getOrganizations(forceRefresh: true);
      expect(fakeService.getOrganizationsCallCount, 2);
    });

    test('getOrganizations com includeDisabled=true retorna desativadas', () async {
      final all = await repository.getOrganizations(includeDisabled: true);

      expect(all.length, 3);
      expect(all.map((o) => o.id), containsAll(['1', '2', '3']));
    });

    test('getOrganization retorna do cache se previamente carregado', () async {
      await repository.getOrganizations();

      final found = await repository.getOrganization('1');
      expect(found.tradeName, 'Liga Nacional');
    });

    test('deleteOrganization chama service e limpa cache', () async {
      await repository.getOrganizations();
      expect(fakeService.getOrganizationsCallCount, 1);

      await repository.deleteOrganization('1');
      expect(fakeService.deleteCallCount, 1);

      // Nova consulta deve bater no service novamente
      final updated = await repository.getOrganizations();
      expect(fakeService.getOrganizationsCallCount, 2);
      expect(updated.map((o) => o.id), isNot(contains('1')));
    });

    test('reactivateOrganization chama service e limpa cache', () async {
      await repository.reactivateOrganization('3');
      expect(fakeService.reactivateCallCount, 1);

      final activeList = await repository.getOrganizations();
      expect(activeList.map((o) => o.id), contains('3'));
    });

    test('propaga erro quando service falha', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Falha de conexão com backend';

      expect(
        () => repository.getOrganizations(forceRefresh: true),
        throwsA(isA<Exception>()),
      );
    });
  });
}
