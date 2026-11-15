import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/errors/app_failure.dart';
import 'package:mindverse/core/errors/game_exception.dart';

void main() {
  group('AppFailure Tests', () {
    test('StorageFailure retains message and cause', () {
      const failure = StorageFailure('Disk full', 42);
      expect(failure.message, 'Disk full');
      expect(failure.cause, 42);
      expect(failure.toString(), contains('StorageFailure'));
      expect(failure.toString(), contains('Disk full'));
    });

    test('IntegrityFailure formats properly', () {
      const failure = IntegrityFailure('Checksum mismatch');
      expect(failure.message, 'Checksum mismatch');
      expect(failure.toString(), contains('IntegrityFailure'));
    });
  });

  group('GameException Tests', () {
    test('InvalidMoveException holds context', () {
      const exception = InvalidMoveException(
        'Cannot rotate locked block',
        gameId: 'cube_logic',
        levelNumber: 3,
      );
      expect(exception.message, 'Cannot rotate locked block');
      expect(exception.gameId, 'cube_logic');
      expect(exception.levelNumber, 3);
      expect(exception.toString(), contains('cube_logic'));
      expect(exception.toString(), contains('Level: 3'));
    });
  });
}
