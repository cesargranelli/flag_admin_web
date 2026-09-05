/// Feature: Organizações.
///
/// Exporta todas as partes da feature.
library;

// Data + Domain layers
// (o modelo Organization vive em lib/src/domain/models/organization.dart;
// o acesso a dados é 100% via REST — OrganizationApi em lib/src/api/services)

// Presentation layer
export 'presentation/screens/organizations_screen.dart';
export 'presentation/screens/organization_detail_screen.dart';
export 'presentation/screens/organization_form_screen.dart';
