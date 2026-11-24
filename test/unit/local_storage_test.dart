import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

void main() {
  group('LocalStorageService transactional storage', () {
    late SharedPreferences prefs;
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = await createTestLocalStorage(prefs);
    });

    tearDown(() async {
      await storage.close();
    });

    test('writes and reads a document', () async {
      final doc = {'username': 'Tactician', 'xp': 250};
      await storage.writeDocument('test_profile.json', doc);

      final retrieved = await storage.readDocument('test_profile.json');
      expect(retrieved, doc);
    });

    test('replacing a document stores the latest complete value', () async {
      await storage.writeDocument('save.json', {'coins': 100, 'xp': 20});
      await storage.writeDocument('save.json', {'coins': 200});

      expect(await storage.readDocument('save.json'), {'coins': 200});
    });

    test('removeDocument deletes a stored document', () async {
      await storage.writeDocument('temp.json', {'status': 'active'});
      expect(await storage.readDocument('temp.json'), isNotNull);

      await storage.removeDocument('temp.json');
      expect(await storage.readDocument('temp.json'), isNull);
    });
  });
}
