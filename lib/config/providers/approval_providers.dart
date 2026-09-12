/// Approval domain providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flag_admin_web/ui/approval/view_models/approval_list_view_model.dart';

import 'auth_providers.dart';

/// ViewModel para a listagem de aprovações (ADR-011 / MVVM).
final approvalListViewModelProvider =
    ChangeNotifierProvider.autoDispose<ApprovalListViewModel>(
      (ref) =>
          ApprovalListViewModel(repository: ref.watch(authRepositoryProvider)),
    );
