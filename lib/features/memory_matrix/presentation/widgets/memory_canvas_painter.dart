import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/memory_board.dart';

class MemoryMatrixCanvasPainter extends CustomPainter {
  final MemoryMatrixBoard board;

  MemoryMatrixCanvasPainter({required this.board});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / board.gridSize;
    final cellHeight = size.height / board.gridSize;

    for (int y = 0; y < board.gridSize; y++) {
      for (int x = 0; x < board.gridSize; x++) {
        _drawCell(canvas, x, y, cellWidth, cellHeight);
      }
    }
  }

  void _drawCell(Canvas canvas, int x, int y, double cw, double ch) {
    final rect = Rect.fromLTWH(x * cw + 4, y * ch + 4, cw - 8, ch - 8);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cw * 0.15));

    final isSequenceCell = board.phase == MemoryPhase.memorize &&
        board.sequence.contains((x, y));

    final isPlayerCell = board.playerInput.contains((x, y));

    Color fillColor = AppColors.surfaceCard;
    if (isSequenceCell) {
      fillColor = AppColors.primary;
    } else if (isPlayerCell) {
      fillColor = AppColors.secondary;
    }

    final bgPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant MemoryMatrixCanvasPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}
