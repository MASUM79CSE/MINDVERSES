import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalStorageService> createTestLocalStorage(SharedPreferences preferences) async {
  final database = await newDatabaseFactoryMemory().openDatabase('mindverse-test.db');
  return LocalStorageService.initialize(preferences, database: database);
}
