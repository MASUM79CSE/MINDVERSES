import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/features/perspective/domain/perspective_level_factory.dart';

void main() {
  group('Perspective Domain & Factory', () {
    test('Builds all 10 Perspective levels successfully', () {
      for (int i = 1; i <= 10; i++) {
        final level = PerspectiveLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.initialBoard.shapes.isNotEmpty, isTrue);
      }
    });
  });
}
