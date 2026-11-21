import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen allows updating username and picking avatar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ProfileScreen(),
      ),
    );

    expect(find.text('Player1234'), findsOneWidget);
    expect(find.text('Novice Thinker • Level 1'), findsOneWidget);
    expect(find.text('OVERALL PERFORMANCE'), findsOneWidget);

    // Tap edit icon to open username dialog
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Edit Username'), findsOneWidget);

    // Enter new name and save
    await tester.enterText(find.byType(TextField), 'GrandmasterMind');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('GrandmasterMind'), findsOneWidget);

    // Tap avatar to open bottom sheet
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Avatar'), findsOneWidget);

    // Pick second avatar
    await tester.tap(find.byIcon(Icons.psychology_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
  });
}
