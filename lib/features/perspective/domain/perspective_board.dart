import 'package:flutter/foundation.dart';
import 'perspective_shape.dart';

@immutable
class PerspectiveBoard {
  final Map<String, PerspectiveShape> shapes;
  final bool isSolved;

  const PerspectiveBoard({
    required this.shapes,
    this.isSolved = false,
  });

  PerspectiveBoard withShape(PerspectiveShape updated) {
    final newShapes = Map<String, PerspectiveShape>.from(shapes)..[updated.id] = updated;
    final solved = newShapes.values.every((s) => s.isAligned);
    return PerspectiveBoard(
      shapes: newShapes,
      isSolved: solved,
    );
  }
}
