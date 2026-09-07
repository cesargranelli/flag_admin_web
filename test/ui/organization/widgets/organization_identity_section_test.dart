import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/src/core/theme/app_colors.dart';
import 'package:flag_admin_web/ui/organization/widgets/components/organization_identity_section.dart';

void main() {
  group('OrganizationIdentitySection Widget Tests', () {
    late TextEditingController tradeNameController;
    late TextEditingController abbreviationController;
    late TextEditingController logoUrlController;
    late TextEditingController primaryColorController;
    late TextEditingController secondaryColorController;
    late TextEditingController tertiaryColorController;
    late TextEditingController quaternaryColorController;
    late TextEditingController localeController;
    bool dirtyCalled = false;

    setUp(() {
      tradeNameController = TextEditingController(text: 'Time Teste');
      abbreviationController = TextEditingController(text: 'TT');
      logoUrlController = TextEditingController();
      primaryColorController = TextEditingController();
      secondaryColorController = TextEditingController();
      tertiaryColorController = TextEditingController();
      quaternaryColorController = TextEditingController();
      localeController = TextEditingController(text: 'pt_BR');
      dirtyCalled = false;
    });

    tearDown(() {
      tradeNameController.dispose();
      abbreviationController.dispose();
      logoUrlController.dispose();
      primaryColorController.dispose();
      secondaryColorController.dispose();
      tertiaryColorController.dispose();
      quaternaryColorController.dispose();
      localeController.dispose();
    });

    testWidgets('circulo do input de cor reage em tempo real as mudancas no controller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrganizationIdentitySection(
                tradeNameController: tradeNameController,
                abbreviationController: abbreviationController,
                logoUrlController: logoUrlController,
                primaryColorController: primaryColorController,
                secondaryColorController: secondaryColorController,
                tertiaryColorController: tertiaryColorController,
                quaternaryColorController: quaternaryColorController,
                localeController: localeController,
                localeOptions: const [('pt_BR', 'Português (Brasil)')],
                onDirty: () => dirtyCalled = true,
              ),
            ),
          ),
        ),
      );

      // Inicialmente com controller vazio, deve usar a fallbackColor (AppColors.primary)
      final primaryFieldFinder = find.widgetWithText(TextFormField, '#FD6B22');
      expect(primaryFieldFinder, findsWidgets);

      // Altera a cor primária para verde (#00FF00)
      primaryColorController.text = '#00FF00';
      await tester.pump();

      // Encontra os containers circulares de 24x24 que representam os circulos de prefixo dos inputs
      final circleContainers = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) => w is Container &&
              w.constraints?.maxWidth == 24 &&
              w.constraints?.maxHeight == 24 &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );

      expect(circleContainers, isNotEmpty);
      final primaryCircleDecoration = circleContainers.first.decoration as BoxDecoration;
      expect(primaryCircleDecoration.color, equals(const Color(0xFF00FF00)));

      // Altera novamente para azul (#0000FF)
      primaryColorController.text = '#0000FF';
      await tester.pump();

      final updatedCircleContainers = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) => w is Container &&
              w.constraints?.maxWidth == 24 &&
              w.constraints?.maxHeight == 24 &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );

      final updatedDecoration = updatedCircleContainers.first.decoration as BoxDecoration;
      expect(updatedDecoration.color, equals(const Color(0xFF0000FF)));
    });
  });
}
