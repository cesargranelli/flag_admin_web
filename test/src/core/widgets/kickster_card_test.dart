import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flag_admin_web/src/core/widgets/kickster_card.dart';

void main() {
  group('KicksterCard Widget Tests', () {
    testWidgets('renderiza layout em linha com icone padrao quando imageUrl e nulo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KicksterCard(
              icon: Icons.business,
              title: 'Organizacao Teste',
              subtitle: 'Subtitulo Teste',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Organizacao Teste'), findsOneWidget);
      expect(find.text('Subtitulo Teste'), findsOneWidget);
      expect(find.byIcon(Icons.business), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renderiza layout em linha com Image.network otimizada com ResizeImage quando imageUrl e fornecido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KicksterCard(
              icon: Icons.business,
              title: 'Organizacao com Logo',
              subtitle: 'Subtitulo',
              imageUrl: 'https://example.com/logo.png',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Organizacao com Logo'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<ResizeImage>());
      final resizeImage = imageWidget.image as ResizeImage;
      expect(resizeImage.width, equals(96));
      expect(resizeImage.height, equals(96));
      expect(resizeImage.imageProvider, isA<NetworkImage>());
      final networkImage = resizeImage.imageProvider as NetworkImage;
      expect(networkImage.url, equals('https://example.com/logo.png'));
    });

    testWidgets('renderiza layout em tile com Image.network otimizada quando imageUrl e fornecido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KicksterCard(
              icon: Icons.shield,
              title: 'Card Tile',
              imageUrl: 'https://example.com/tile-icon.png',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Card Tile'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<ResizeImage>());
      final resizeImage = imageWidget.image as ResizeImage;
      expect(resizeImage.width, equals(112));
      expect(resizeImage.height, equals(112));
      expect(resizeImage.imageProvider, isA<NetworkImage>());
      final networkImage = resizeImage.imageProvider as NetworkImage;
      expect(networkImage.url, equals('https://example.com/tile-icon.png'));
    });
  });
}
