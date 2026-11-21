import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/core/widgets/app_dialog.dart';
import 'package:mindverse/core/widgets/coin_badge.dart';
import 'package:mindverse/core/widgets/empty_state_view.dart';
import 'package:mindverse/core/widgets/loading_view.dart';
import 'package:mindverse/core/widgets/pause_modal.dart';
import 'package:mindverse/core/widgets/xp_progress_bar.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Dialogs and Modals Tests', () {
    testWidgets('AppDialog renders title, message, and executes callback', (tester) async {
      bool actionFired = false;

      await tester.pumpWidget(
        wrapWithTheme(
          AppDialog(
            title: 'Test Title',
            message: 'Test Message Body',
            primaryActionLabel: 'Confirm',
            onPrimaryAction: () => actionFired = true,
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message Body'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pump();

      expect(actionFired, isTrue);
    });

    testWidgets('PauseModal renders game context and executes resume', (tester) async {
      bool resumed = false;
      bool restarted = false;
      bool exited = false;

      await tester.pumpWidget(
        wrapWithTheme(
          PauseModal(
            gameTitle: 'Cube Logic',
            levelNumber: 5,
            onResume: () => resumed = true,
            onRestart: () => restarted = true,
            onExit: () => exited = true,
          ),
        ),
      );

      expect(find.text('GAME PAUSED'), findsOneWidget);
      expect(find.text('Cube Logic — Level 5'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump();
      expect(resumed, isTrue);

      await tester.tap(find.text('Restart Level'));
      await tester.pump();
      expect(restarted, isTrue);

      await tester.tap(find.text('Exit to Levels'));
      await tester.pump();
      expect(exited, isTrue);
    });

    testWidgets('EmptyStateView renders title, description, and action button', (tester) async {
      bool actionFired = false;

      await tester.pumpWidget(
        wrapWithTheme(
          EmptyStateView(
            icon: Icons.hourglass_empty_rounded,
            title: 'No Data',
            description: 'Please try again later.',
            actionLabel: 'Refresh',
            onAction: () => actionFired = true,
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Please try again later.'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pump();

      expect(actionFired, isTrue);
    });

    testWidgets('LoadingView displays message when provided', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const LoadingView(message: 'Generating Level...'),
        ),
      );

      expect(find.text('Generating Level...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('XpProgressBar renders level and XP metrics', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const XpProgressBar(
            currentXp: 75,
            nextLevelXp: 150,
            playerLevel: 2,
          ),
        ),
      );

      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('75 / 150 XP'), findsOneWidget);
    });

    testWidgets('CoinBadge displays coin count and fires onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          CoinBadge(
            coins: 250,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('250'), findsOneWidget);
      await tester.tap(find.text('250'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
