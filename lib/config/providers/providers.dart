/// Flag Admin Web — Riverpod Providers.
library;
///
/// Barrel file that exports all providers organized by domain.
///
/// Usage:
/// ```dart
/// import 'package:flag_admin_web/config/providers/providers.dart';
/// ```
///
/// This file re-exports:
/// - **Base providers**: session, API client, router
/// - **Auth providers**: auth service, repository, controller + viewmodels
/// - **User providers**: user repository + viewmodels
/// - **Approval providers**: approval viewmodel
/// - **Competition providers**: services, repositories, viewmodels, list providers
/// - **Organization providers**: services, repositories, viewmodels
/// - **Institution providers**: services, repositories, viewmodels
/// - **Game providers**: services, repositories, viewmodels
/// - **Round providers**: services, repositories, viewmodels
/// - **Venue providers**: services, repositories, viewmodels
/// - **Person providers**: services, repositories, viewmodels
/// - **Roster providers**: services, repositories, viewmodels

export 'base_providers.dart';
export 'auth_providers.dart';
export 'user_providers.dart';
export 'approval_providers.dart';
export 'competition_providers.dart';
export 'organization_providers.dart';
export 'institution_providers.dart';
export 'game_providers.dart';
export 'round_providers.dart';
export 'venue_providers.dart';
export 'person_providers.dart';
export 'roster_providers.dart';
