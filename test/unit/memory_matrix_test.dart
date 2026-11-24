import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/features/memory_matrix/domain/memory_matrix_level_factory.dart';

void main() {
  group('Memory Matrix Domain & Factory', () {
    test('Builds all 10 Memory Matrix levels successfully', () {
      for (int i = 1; i <= 10; i++) {
        final level = MemoryMatrixLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.initialBoard.sequence.isNotEmpty, isTrue);
      }
    });

    test('sequences stay inside the grid', () {
      for (int i = 1; i <= 10; i++) {
        final level = MemoryMatrixLevelFactory.build(i);
        final grid = level.initialBoard.gridSize;
        for (final (x, y) in level.initialBoard.sequence) {
          expect(x, inInclusiveRange(0, grid - 1));
          expect(y, inInclusiveRange(0, grid - 1));
        }
      }
    });

    test('standard levels never repeat a cell', () {
      for (int i = 2; i <= 10; i++) {
        final sequence = MemoryMatrixLevelFactory.build(i).initialBoard.sequence;
        expect(
          sequence.toSet(),
          hasLength(sequence.length),
          reason: 'Level $i repeats a cell instead of sampling new ones',
        );
      }
    });

    test('5x5 sequences no longer repeat every five taps', () {
      for (final levelNumber in [6, 7, 8, 9, 10]) {
        final level = MemoryMatrixLevelFactory.build(levelNumber);
        expect(level.initialBoard.gridSize, 5);
        final sequence = level.initialBoard.sequence;
        expect(sequence.length, greaterThan(5));
        final firstFive = sequence.take(5).toList();
        final nextFive = sequence.skip(5).take(5).toList();
        expect(
          nextFive,
          isNot(equals(firstFive)),
          reason: 'Level $levelNumber still repeats its first five taps',
        );
      }
    });
  });
}
