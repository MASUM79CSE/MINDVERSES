import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/kingdom_board.dart';
import '../../domain/kingdom_tile.dart';

class KingdomCanvasPainter extends CustomPainter {
  final KingdomBoard board;

  KingdomCanvasPainter({required this.board});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / board.width;
    final cellHeight = size.height / board.height;

    for (int y = 0; y < board.height; y++) {
      for (int x = 0; x < board.width; x++) {
        final tile = board.tileAt(x, y);
        if (tile != null) {
          _drawCell(canvas, x, y, cellWidth, cellHeight, tile);
        }
      }
    }
  }

  void _drawCell(Canvas canvas, int x, int y, double cw, double ch, KingdomTile tile) {
    final rect = Rect.fromLTWH(x * cw + 4, y * ch + 4, cw - 8, ch - 8);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cw * 0.15));

    Color fillColor;
    switch (tile.buildingType) {
      case BuildingType.empty:
        fillColor = AppColors.surfaceCard;
        break;
      case BuildingType.house:
        fillColor = AppColors.primary;
        break;
      case BuildingType.farm:
        fillColor = AppColors.energyActive;
        break;
      case BuildingType.mill:
        fillColor = AppColors.secondary;
        break;
      case BuildingType.market:
        fillColor = AppColors.starGold;
        break;
      case BuildingType.castle:
        fillColor = AppColors.gamePatternMatrix;
        break;
      case BuildingType.wall:
        fillColor = AppColors.surfaceElevated;
        break;
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

    // Label initial letter
    if (tile.buildingType != BuildingType.empty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: tile.buildingType.displayName[0],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textInverse,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, rect.center - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant KingdomCanvasPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}
