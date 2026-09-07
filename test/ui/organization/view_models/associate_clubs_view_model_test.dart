import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/ui/organization/view_models/associate_clubs_view_model.dart';

void main() {
  group('AssociateClubsViewModel', () {
    late AssociateClubsViewModel viewModel;

    setUp(() {
      viewModel = AssociateClubsViewModel();
    });

    test('estado inicial limpo', () {
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.selectedOrgIds, isEmpty);
      expect(viewModel.isSubmittingBatch, isFalse);
    });

    test('toggleSelection adiciona e remove IDs', () {
      viewModel.toggleSelection('club-1');
      expect(viewModel.selectedOrgIds, contains('club-1'));

      viewModel.toggleSelection('club-1');
      expect(viewModel.selectedOrgIds, isEmpty);
    });

    test('selectAll e clearSelection gerenciam coleção', () {
      viewModel.selectAll(['c1', 'c2', 'c3']);
      expect(viewModel.selectedOrgIds.length, 3);

      viewModel.clearSelection();
      expect(viewModel.selectedOrgIds, isEmpty);
    });

    test('setSearchQuery e setSubmittingBatch notificam alterações', () {
      viewModel.setSearchQuery('Tubarões');
      expect(viewModel.searchQuery, 'Tubarões');

      viewModel.setSubmittingBatch(true);
      expect(viewModel.isSubmittingBatch, isTrue);
    });
  });
}
