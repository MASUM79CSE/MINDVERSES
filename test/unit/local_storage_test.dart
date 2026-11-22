import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalStorageService Integrity Tests', () {
    late SharedPreferences prefs;
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
    });

    test('writes and reads document with verified HMAC signature', () async {
      final doc = {'username': 'Tactician', 'xp': 250};
      await storage.writeDocument('test_profile.json', doc);

      final retrieved = await storage.readDocument('test_profile.json');
      expect(retrieved, isNotNull);
      expect(retrieved!['username'], 'Tactician');
      expect(retrieved['xp'], 250);
    });

    test('recovers from backup when primary document is modified/tampered', () async {
      // Write initial state (becomes backup upon second write)
      await storage.writeDocument('save.json', {'coins': 100});
      // Write updated state
      await storage.writeDocument('save.json', {'coins': 200});

      // Tamper with primary save document (invalidating signature)
      await prefs.setString('save.json', '{"coins": 999999}');

      // Read should detect mismatch and recover backup (coins: 100)
      final recovered = await storage.readDocument('save.json');
      expect(recovered, isNotNull);
      expect(recovered!['coins'], 100);
    });

    test('removeDocument deletes primary, backup, and signature keys', () async {
      await storage.writeDocument('temp.json', {'status': 'active'});
      expect(prefs.containsKey('temp.json'), isTrue);
      expect(prefs.containsKey('temp.json_sig'), isTrue);

      await storage.removeDocument('temp.json');
      expect(prefs.containsKey('temp.json'), isFalse);
      expect(prefs.containsKey('temp.json_sig'), isFalse);
    });
  });
}
