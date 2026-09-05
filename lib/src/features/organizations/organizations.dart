/// Feature: Organizações.
///
/// Exporta todas as partes da feature.
library;

// Data layer
export 'data/datasources/organization_firestore_service.dart';
export 'data/repositories/organization_repository.dart';

// Domain layer
// (o modelo Organization vive em lib/src/domain/models/organization.dart;
// mapeado do Firestore em data/datasources/organization_firestore_service.dart)

// Presentation layer
export 'presentation/screens/organizations_screen.dart';
export 'presentation/screens/organization_detail_screen.dart';
export 'presentation/screens/organization_form_screen.dart';
