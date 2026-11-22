import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/features/profile/presentation/profile_screen.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ProfileScreen allows updating username and picking avatar with Riverpod', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

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

    // Tap camera icon to open avatar bottom sheet
    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Avatar'), findsOneWidget);

    // Pick second avatar - tap last found psychology_rounded (in bottom sheet)
    await tester.tap(find.byIcon(Icons.psychology_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.psychology_rounded), findsWidgets);
  });
}
