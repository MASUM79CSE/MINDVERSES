import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/maze_board.dart';
import '../../domain/maze_tile.dart';

/// CustomPainter rendering grid cells, sliding path/wall tiles, start, destination, and selection.
class MazeBoardPainter extends CustomPainter {
  final MazeBoard board;
  final (int, int)? selectedCoord;

  MazeBoardPainter({
    required this.board,
    this.selectedCoord,
  });

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

  void _drawCell(Canvas canvas, int x, int y, double cw, double ch, MazeTile tile) {
    final rect = Rect.fromLTWH(x * cw + 4, y * ch + 4, cw - 8, ch - 8);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cw * 0.15));

    final isSelected = selectedCoord != null && selectedCoord!.$1 == x && selectedCoord!.$2 == y;

    Color fillColor;
    switch (tile.type) {
      case MazeTileType.start:
        fillColor = AppColors.energyActive;
        break;
      case MazeTileType.destination:
        fillColor = AppColors.secondary;
        break;
      case MazeTileType.wall:
        fillColor = AppColors.surfaceElevated;
        break;
      case MazeTileType.path:
      case MazeTileType.movable:
        fillColor = AppColors.surfaceCard;
        break;
    }

    final bgPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = isSelected ? AppColors.primary : AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.5;
    canvas.drawRRect(rrect, borderPaint);

    // Draw the tile's open sides as corridors so the player can read which
    // neighbours each tile connects to. Without this the puzzle would be
    // unsolvable by inspection.
    final corridorColor = switch (tile.type) {
      MazeTileType.start => AppColors.energyActive,
      MazeTileType.destination => AppColors.secondary,
      _ => AppColors.primary,
    };
    final corridorPaint = Paint()
      ..color = corridorColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final thickness = (cw < ch ? cw : ch) * 0.22;
    final half = thickness / 2;
    final center = rect.center;

    if (tile.isOpenNorth) {
      canvas.drawRect(
        Rect.fromLTRB(center.dx - half, rect.top, center.dx + half, center.dy),
        corridorPaint,
      );
    }
    if (tile.isOpenSouth) {
      canvas.drawRect(
        Rect.fromLTRB(center.dx - half, center.dy, center.dx + half, rect.bottom),
        corridorPaint,
      );
    }
    if (tile.isOpenWest) {
      canvas.drawRect(
        Rect.fromLTRB(rect.left, center.dy - half, center.dx, center.dy + half),
        corridorPaint,
      );
    }
    if (tile.isOpenEast) {
      canvas.drawRect(
        Rect.fromLTRB(center.dx, center.dy - half, rect.right, center.dy + half),
        corridorPaint,
      );
    }

    // Draw icon or text for start/destination
    if (tile.type == MazeTileType.start) {
      _drawIcon(canvas, rect.center, Icons.play_arrow_rounded, AppColors.textInverse);
    } else if (tile.type == MazeTileType.destination) {
      _drawIcon(canvas, rect.center, Icons.flag_rounded, AppColors.textInverse);
    }
  }

  void _drawIcon(Canvas canvas, Offset center, IconData iconData, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MazeBoardPainter oldDelegate) {
    return oldDelegate.board != board || oldDelegate.selectedCoord != selectedCoord;
  }
}
