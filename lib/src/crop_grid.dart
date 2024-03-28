import 'dart:ui';

import 'package:flutter/material.dart';
import 'crop_rect.dart';

/// Crop Grid with invisible border, for better touch detection.
class CropGrid extends StatelessWidget {
  final Rect crop;
  final Color gridColor;
  final Color gridInnerColor;
  final Color gridCornerColor;
  final double paddingSize;
  final double cornerSize;
  final double thinWidth;
  final double thickWidth;
  final Color scrimColor;
  final bool showCorners;
  final bool alwaysShowThirdLines;
  final bool isMoving;
  final ValueChanged<Size> onSize;

  const CropGrid({
    Key? key,
    required this.crop,
    required this.gridColor,
    required this.gridInnerColor,
    required this.gridCornerColor,
    required this.paddingSize,
    required this.cornerSize,
    required this.thinWidth,
    required this.thickWidth,
    required this.scrimColor,
    required this.showCorners,
    required this.alwaysShowThirdLines,
    required this.isMoving,
    required this.onSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(foregroundPainter: _CropGridPainter(this)),
      );
}

class _CropGridPainter extends CustomPainter {
  final CropGrid grid;

  _CropGridPainter(this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final Size imageSize = Size(
      size.width - 2 * grid.paddingSize,
      size.height - 2 * grid.paddingSize,
    );
    final Rect full = Offset(grid.paddingSize, grid.paddingSize) & imageSize;
    final Rect bounds = grid.crop
        .multiply(imageSize)
        .translate(grid.paddingSize, grid.paddingSize);
    grid.onSize(imageSize);

    canvas.save();
    canvas.clipRect(bounds, clipOp: ClipOp.difference);
    canvas.drawRect(
        full,
        Paint() //
          ..color = grid.scrimColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true);
    canvas.restore();

    if (grid.showCorners)
      canvas.drawPath(
          Path() //
            ..addPolygon([
              bounds.topLeft.translate(0, grid.cornerSize),
              bounds.topLeft,
              bounds.topLeft.translate(grid.cornerSize, 0)
            ], false)
            ..addPolygon([
              bounds.topRight.translate(0, grid.cornerSize),
              bounds.topRight,
              bounds.topRight.translate(-grid.cornerSize, 0)
            ], false)
            ..addPolygon([
              bounds.bottomLeft.translate(0, -grid.cornerSize),
              bounds.bottomLeft,
              bounds.bottomLeft.translate(grid.cornerSize, 0)
            ], false)
            ..addPolygon([
              bounds.bottomRight.translate(0, -grid.cornerSize),
              bounds.bottomRight,
              bounds.bottomRight.translate(-grid.cornerSize, 0)
            ], false),
          Paint()
            ..color = grid.gridCornerColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = grid.thickWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.miter
            ..isAntiAlias = true);

    canvas.drawPath(
        Path() //
          ..addPolygon([
            bounds.topLeft.translate(grid.cornerSize, 0),
            bounds.topRight.translate(-grid.cornerSize, 0)
          ], false)
          ..addPolygon([
            bounds.bottomLeft.translate(grid.cornerSize, 0),
            bounds.bottomRight.translate(-grid.cornerSize, 0)
          ], false)
          ..addPolygon([
            bounds.topLeft.translate(0, grid.cornerSize),
            bounds.bottomLeft.translate(0, -grid.cornerSize)
          ], false)
          ..addPolygon([
            bounds.topRight.translate(0, grid.cornerSize),
            bounds.bottomRight.translate(0, -grid.cornerSize)
          ], false),
        Paint()
          ..color = grid.gridColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = grid.thinWidth
          ..strokeCap = StrokeCap.butt
          ..isAntiAlias = true);

    if (grid.isMoving || grid.alwaysShowThirdLines) {
      final thirdHeight = bounds.height / 3.0;
      final thirdWidth = bounds.width / 3.0;
      canvas.drawPath(
          Path() //
            ..addPolygon([
              bounds.topLeft.translate(0, thirdHeight),
              bounds.topRight.translate(0, thirdHeight)
            ], false)
            ..addPolygon([
              bounds.bottomLeft.translate(0, -thirdHeight),
              bounds.bottomRight.translate(0, -thirdHeight)
            ], false)
            ..addPolygon([
              bounds.topLeft.translate(thirdWidth, 0),
              bounds.bottomLeft.translate(thirdWidth, 0)
            ], false)
            ..addPolygon([
              bounds.topRight.translate(-thirdWidth, 0),
              bounds.bottomRight.translate(-thirdWidth, 0)
            ], false),
          Paint()
            ..color = grid.gridInnerColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = grid.thinWidth
            ..strokeCap = StrokeCap.butt
            ..isAntiAlias = true);
    }
  }

  @override
  bool shouldRepaint(_CropGridPainter oldDelegate) =>
      oldDelegate.grid.crop != grid.crop || //
      oldDelegate.grid.isMoving != grid.isMoving ||
      oldDelegate.grid.cornerSize != grid.cornerSize ||
      oldDelegate.grid.gridColor != grid.gridColor ||
      oldDelegate.grid.gridCornerColor != grid.gridCornerColor ||
      oldDelegate.grid.gridInnerColor != grid.gridInnerColor;

  @override
  bool hitTest(Offset position) => true;
}
