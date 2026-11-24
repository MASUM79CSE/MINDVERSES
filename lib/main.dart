import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/services/logger_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/storage_database.dart';
import 'shared/providers/shared_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggerService.info('Initializing MINDVERSE core systems...');

  final sharedPreferences = await SharedPreferences.getInstance();
  final database = await openStorageDatabase();
  final localStorage = await LocalStorageService.initialize(
    sharedPreferences,
    database: database,
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        localStorageServiceProvider.overrideWithValue(localStorage),
      ],
      child: const MindverseApp(),
    ),
  );
}
