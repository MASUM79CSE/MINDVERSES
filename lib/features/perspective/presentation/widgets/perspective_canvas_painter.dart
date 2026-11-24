import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/perspective_board.dart';

class PerspectiveCanvasPainter extends CustomPainter {
  final PerspectiveBoard board;

  PerspectiveCanvasPainter({required this.board});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final shape in board.shapes.values) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.angleY);

      final paint = Paint()
        ..color = shape.isAligned ? AppColors.energyActive : AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      // Draw projected perspective wireframe box / shape
      final rect = Rect.fromCenter(center: Offset.zero, width: size.width * 0.4, height: size.height * 0.4);
      canvas.drawRect(rect, paint);

      // Draw crosshairs
      canvas.drawLine(Offset(-size.width * 0.25, 0), Offset(size.width * 0.25, 0), paint);
      canvas.drawLine(Offset(0, -size.height * 0.25), Offset(0, size.height * 0.25), paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PerspectiveCanvasPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}
