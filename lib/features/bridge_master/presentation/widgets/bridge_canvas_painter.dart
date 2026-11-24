import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/bridge_joint.dart';
import '../../domain/bridge_member.dart';

/// CustomPainter rendering canyon banks, grid snapping dots, structural members,
/// stress-coded colors, joint nodes, and moving load vehicle.
class BridgeCanvasPainter extends CustomPainter {
  final Map<String, BridgeJoint> joints;
  final List<BridgeMember> members;
  final double gapWidth;
  final double vehicleX;
  final bool isSimulating;
  final String? selectedJointId;

  BridgeCanvasPainter({
    required this.joints,
    required this.members,
    required this.gapWidth,
    required this.vehicleX,
    required this.isSimulating,
    this.selectedJointId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / (gapWidth + 4.0);
    final scaleY = size.height / 10.0;
    final offsetX = scaleX * 2.0;

    _drawCanyon(canvas, size, scaleX, scaleY, offsetX);
    _drawGridDots(canvas, size, scaleX, scaleY, offsetX);
    _drawMembers(canvas, scaleX, scaleY, offsetX);
    _drawJoints(canvas, scaleX, scaleY, offsetX);
    _drawVehicle(canvas, scaleX, scaleY, offsetX);
  }

  Offset _toCanvasPoint(double x, double y, double scaleX, double scaleY, double offsetX) {
    return Offset(offsetX + x * scaleX, y * scaleY);
  }

  void _drawCanyon(Canvas canvas, Size size, double scaleX, double scaleY, double offsetX) {
    // Water at bottom
    final waterPaint = Paint()..color = const Color(0xFF1E3A8A).withValues(alpha: 0.8);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25), waterPaint);

    // Left cliff
    final cliffPaint = Paint()..color = AppColors.surfaceElevated;
    final leftCliff = Path()
      ..moveTo(0, size.height)
      ..lineTo(offsetX, size.height)
      ..lineTo(offsetX, 5 * scaleY)
      ..lineTo(0, 5 * scaleY)
      ..close();
    canvas.drawPath(leftCliff, cliffPaint);

    // Right cliff
    final rightX = offsetX + gapWidth * scaleX;
    final rightCliff = Path()
      ..moveTo(rightX, 5 * scaleY)
      ..lineTo(size.width, 5 * scaleY)
      ..lineTo(size.width, size.height)
      ..lineTo(rightX, size.height)
      ..close();
    canvas.drawPath(rightCliff, cliffPaint);
  }

  void _drawGridDots(Canvas canvas, Size size, double scaleX, double scaleY, double offsetX) {
    if (isSimulating) return;

    final dotPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= gapWidth; x += 1.0) {
      for (double y = 1; y <= 8; y += 1.0) {
        final pos = _toCanvasPoint(x, y, scaleX, scaleY, offsetX);
        canvas.drawCircle(pos, 2.0, dotPaint);
      }
    }
  }

  void _drawMembers(Canvas canvas, double scaleX, double scaleY, double offsetX) {
    for (final m in members) {
      if (m.isSnapped) continue;

      final jA = joints[m.jointAId];
      final jB = joints[m.jointBId];
      if (jA == null || jB == null) continue;

      final posA = _toCanvasPoint(jA.x, jA.y, scaleX, scaleY, offsetX);
      final posB = _toCanvasPoint(jB.x, jB.y, scaleX, scaleY, offsetX);

      Color color;
      if (isSimulating) {
        if (m.stressRatio > 0.8) {
          color = AppColors.stressCritical;
        } else if (m.stressRatio > 0.5) {
          color = AppColors.stressWarning;
        } else {
          color = AppColors.energyActive;
        }
      } else {
        color = switch (m.materialType) {
          BridgeMaterialType.roadDeck => AppColors.primary,
          BridgeMaterialType.woodBeam => AppColors.secondary,
          BridgeMaterialType.steelTruss => AppColors.textPrimary,
          BridgeMaterialType.steelCable => AppColors.textSecondary,
        };
      }

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = m.materialType == BridgeMaterialType.roadDeck ? 6.0 : 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(posA, posB, paint);
    }
  }

  void _drawJoints(Canvas canvas, double scaleX, double scaleY, double offsetX) {
    for (final j in joints.values) {
      final pos = _toCanvasPoint(j.x, j.y, scaleX, scaleY, offsetX);
      final isSelected = j.id == selectedJointId;

      final paint = Paint()
        ..color = j.isAnchor ? AppColors.secondary : (isSelected ? AppColors.primary : AppColors.textPrimary)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, j.isAnchor ? 8.0 : (isSelected ? 7.0 : 5.0), paint);

      if (isSelected) {
        final glow = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(pos, 10.0, glow);
      }
    }
  }

  void _drawVehicle(Canvas canvas, double scaleX, double scaleY, double offsetX) {
    if (!isSimulating && vehicleX <= 0) return;

    final pos = _toCanvasPoint(vehicleX, 5.0, scaleX, scaleY, offsetX);

    // Vehicle body
    final truckRect = Rect.fromLTWH(pos.dx - 18, pos.dy - 20, 36, 16);
    final truckPaint = Paint()..color = AppColors.secondary;
    canvas.drawRRect(RRect.fromRectAndRadius(truckRect, const Radius.circular(4)), truckPaint);

    // Wheels
    final wheelPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(pos.dx - 10, pos.dy - 2), 4, wheelPaint);
    canvas.drawCircle(Offset(pos.dx + 10, pos.dy - 2), 4, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant BridgeCanvasPainter oldDelegate) {
    return oldDelegate.joints != joints ||
        oldDelegate.members != members ||
        oldDelegate.vehicleX != vehicleX ||
        oldDelegate.isSimulating != isSimulating ||
        oldDelegate.selectedJointId != selectedJointId;
  }
}
