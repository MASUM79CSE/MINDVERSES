import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router/app_router.dart';

/// Synchronous SharedPreferences instance provider, overridden in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// Central router provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// Theme mode provider (defaults to ThemeMode.dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark;
});
