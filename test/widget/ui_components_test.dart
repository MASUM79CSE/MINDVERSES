import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/core/widgets/app_button.dart';
import 'package:mindverse/core/widgets/app_card.dart';
import 'package:mindverse/core/widgets/glass_container.dart';
import 'package:mindverse/core/widgets/star_display.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('UI Components Widget Tests', () {
    testWidgets('AppButton renders label and fires callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          AppButton(
            label: 'Test Button',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('AppCard renders child and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          AppCard(
            onTap: () => tapped = true,
            child: const Text('Card Content'),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('GlassContainer renders child within blur filter', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const GlassContainer(
            child: Text('Frosted Content'),
          ),
        ),
      );

      expect(find.text('Frosted Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('StarDisplay renders 3 stars with correct filled icons', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const StarDisplay(earnedStars: 2),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });
  });
}
