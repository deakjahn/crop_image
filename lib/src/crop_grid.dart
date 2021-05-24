import 'dart:ui';

import 'package:flutter/material.dart';

class CropGrid extends StatelessWidget {
  final Rect crop;
  final Color gridcolor;
  final double cornerSize;
  final double thinWidth;
  final double thickWidth;
  final Color scrimColor;
  final bool alwaysShowThirdLines;
  final bool isMoving;
  final ValueChanged<Size> onSize;

  const CropGrid({
    Key? key,
    required this.crop,
    required this.gridcolor,
    required this.cornerSize,
    required this.thinWidth,
    required this.thickWidth,
    required this.scrimColor,
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
    final Rect full = Offset.zero & size;
    final Rect bounds = Rect.fromLTRB(
      grid.crop.left * full.width,
      grid.crop.top * full.height,
      grid.crop.right * full.width,
      grid.crop.bottom * full.height,
    );
    grid.onSize(size);

    canvas.save();
    canvas.clipRect(bounds, clipOp: ClipOp.difference);
    canvas.drawRect(full, Paint() //
      ..color = grid.scrimColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true);
    canvas.restore();

    canvas.drawPath(
        Path() //
          ..addPolygon([bounds.topLeft.translate(0, grid.cornerSize), bounds.topLeft, bounds.topLeft.translate(grid.cornerSize, 0)], false)
          ..addPolygon([bounds.topRight.translate(0, grid.cornerSize), bounds.topRight, bounds.topRight.translate(-grid.cornerSize, 0)], false)
          ..addPolygon([bounds.bottomLeft.translate(0, -grid.cornerSize), bounds.bottomLeft, bounds.bottomLeft.translate(grid.cornerSize, 0)], false)
          ..addPolygon([bounds.bottomRight.translate(0, -grid.cornerSize), bounds.bottomRight, bounds.bottomRight.translate(-grid.cornerSize, 0)], false),
        Paint()
          ..color = grid.gridcolor
          ..style = PaintingStyle.stroke
          ..strokeWidth = grid.thickWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.miter
          ..isAntiAlias = true);

    final path = Path() //
      ..addPolygon([bounds.topLeft.translate(grid.cornerSize, 0), bounds.topRight.translate(-grid.cornerSize, 0)], false)
      ..addPolygon([bounds.bottomLeft.translate(grid.cornerSize, 0), bounds.bottomRight.translate(-grid.cornerSize, 0)], false)
      ..addPolygon([bounds.topLeft.translate(0, grid.cornerSize), bounds.bottomLeft.translate(0, -grid.cornerSize)], false)
      ..addPolygon([bounds.topRight.translate(0, grid.cornerSize), bounds.bottomRight.translate(0, -grid.cornerSize)], false);

    if (grid.isMoving || grid.alwaysShowThirdLines) {
      final thirdHeight = bounds.height / 3.0;
      path.addPolygon([bounds.topLeft.translate(0, thirdHeight), bounds.topRight.translate(0, thirdHeight)], false);
      path.addPolygon([bounds.bottomLeft.translate(0, -thirdHeight), bounds.bottomRight.translate(0, -thirdHeight)], false);

      final thirdWidth = bounds.width / 3.0;
      path.addPolygon([bounds.topLeft.translate(thirdWidth, 0), bounds.bottomLeft.translate(thirdWidth, 0)], false);
      path.addPolygon([bounds.topRight.translate(-thirdWidth, 0), bounds.bottomRight.translate(-thirdWidth, 0)], false);
    }

    canvas.drawPath(
        path,
        Paint()
          ..color = grid.gridcolor
          ..style = PaintingStyle.stroke
          ..strokeWidth = grid.thinWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.miter
          ..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(_CropGridPainter oldDelegate) =>
      oldDelegate.grid.crop != grid.crop || //
      oldDelegate.grid.isMoving != grid.isMoving;

  @override
  bool hitTest(Offset position) => true;
}
