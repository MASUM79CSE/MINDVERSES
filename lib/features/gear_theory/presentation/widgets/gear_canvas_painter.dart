import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/gear.dart';
import '../../domain/gear_board.dart';

class GearCanvasPainter extends CustomPainter {
  final GearBoard board;

  GearCanvasPainter({required this.board});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / board.width;
    final scaleY = size.height / board.height;

    for (final gear in board.gears.values) {
      _drawGear(canvas, gear, scaleX, scaleY);
    }
    for (final peg in board.pegs) {
      if (board.gearAt(peg) == null) {
        canvas.drawCircle(Offset(peg.x * scaleX, peg.y * scaleY), 7, Paint()..color = AppColors.primary);
      }
    }
  }

  void _drawGear(Canvas canvas, Gear gear, double scaleX, double scaleY) {
    final center = Offset(gear.x * scaleX, gear.y * scaleY);
    final radius = GearBoard.radius(gear) * ((scaleX + scaleY) / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(gear.rotation);

    final gearPaint = Paint()
      ..color = gear.isDriver
          ? AppColors.primary
          : (gear.isTarget ? AppColors.secondary : AppColors.surfaceElevated)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, gearPaint);

    final outlinePaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset.zero, radius, outlinePaint);

    // Draw gear teeth notches
    final toothPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < gear.teeth; i++) {
      final angle = (i * 2 * math.pi) / gear.teeth;
      final tX = math.cos(angle) * (radius + 4);
      final tY = math.sin(angle) * (radius + 4);
      canvas.drawCircle(Offset(tX, tY), 3.0, toothPaint);
    }

    // Center hub
    final hubPaint = Paint()..color = AppColors.background;
    canvas.drawCircle(Offset.zero, radius * 0.25, hubPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GearCanvasPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}
