import 'package:crop_image/crop_image.dart';
import 'package:crop_image/src/crop_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CropImage extends StatefulWidget {
  /// Controls the crop values being applied.
  ///
  /// If null, this widget will create its own [CropController]. If you want to specify initial values of
  /// [aspectRatio] or [defaultCrop], you need to use your own [CropController].
  /// Otherwise, [aspectRatio] will not be enforced and the [defaultCrop] will be the full image.
  final CropController? controller;

  /// The image to be cropped.
  final Image image;

  /// The crop grid color.
  ///
  /// Defaults to 70% white.
  final Color gridColor;

  /// The size of the corner of the crop grid.
  ///
  /// Defaults to 25.
  final double gridCornerSize;

  /// The width of the crop grid thin lines.
  ///
  /// Defaults to 2.
  final double gridThinWidth;

  /// The width of the crop grid thick lines.
  ///
  /// Defaults to 5.
  final double gridThickWidth;

  /// The crop grid scrim (outside area overlay) color.
  ///
  /// Defaults to 54% black.
  final Color scrimColor;

  /// True if third lines of the crop grid are always displayed.
  /// False if third lines are only displayed while the user manipulates the grid.
  ///
  /// Defaults to false.
  final bool alwaysShowThirdLines;

  /// Event called when the user changes the crop rectangle.
  ///
  /// The passed [Rect] is normalized between 0 and 1.
  ///
  /// See also:
  ///
  ///  * [CropController], which can be used to read this and other details of the crop rectangle.
  final ValueChanged<Rect>? onCrop;

  /// The minimum pixel size the crop rectangle can be shrunk to.
  ///
  /// Defaults to 100.
  final double minimumImageSize;

  CropImage({
    Key? key,
    this.controller,
    required this.image,
    this.gridColor = Colors.white70,
    this.gridCornerSize = 25,
    this.gridThinWidth = 2,
    this.gridThickWidth = 5,
    this.scrimColor = Colors.black54,
    this.alwaysShowThirdLines = false,
    this.onCrop,
    this.minimumImageSize = 100,
  }) : super(key: key);

  @override
  _CropImageState createState() => _CropImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(DiagnosticsProperty<CropController>('controller', controller, defaultValue: null));
    properties.add(DiagnosticsProperty<Image>('image', image));
    properties.add(DiagnosticsProperty<Color>('gridColor', gridColor));
    properties.add(DiagnosticsProperty<double>('gridCornerSize', gridCornerSize));
    properties.add(DiagnosticsProperty<double>('gridThinWidth', gridThinWidth));
    properties.add(DiagnosticsProperty<double>('gridThickWidth', gridThickWidth));
    properties.add(DiagnosticsProperty<Color>('scrimColor', scrimColor));
    properties.add(DiagnosticsProperty<bool>('alwaysShowThirdLines', alwaysShowThirdLines));
    properties.add(DiagnosticsProperty<ValueChanged<Rect>>('onCrop', onCrop, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('minimumImageSize', minimumImageSize));
  }
}

enum _CornerTypes { UpperLeft, UpperRight, LowerRight, LowerLeft, None, Move }

class _CropImageState extends State<CropImage> {
  late CropController controller;
  var currentCrop = Rect.zero;
  var size = Size.zero;
  _TouchPoint? panStart;

  Map<_CornerTypes, Offset> get gridCorners => {
        _CornerTypes.UpperLeft: controller.crop.topLeft.scale(size.width, size.height),
        _CornerTypes.UpperRight: controller.crop.topRight.scale(size.width, size.height),
        _CornerTypes.LowerRight: controller.crop.bottomRight.scale(size.width, size.height),
        _CornerTypes.LowerLeft: controller.crop.bottomLeft.scale(size.width, size.height),
      };

  @override
  void initState() {
    super.initState();

    controller = widget.controller ?? CropController();
    controller.addListener(onChange);
    currentCrop = controller.crop;

    widget.image.image //
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, _) => controller.image = info.image));
  }

  @override
  void dispose() {
    controller.removeListener(onChange);
    controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(CropImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller == null && oldWidget.controller != null) {
      controller = CropController.fromValue(oldWidget.controller!.value);
    } else if (widget.controller != null && oldWidget.controller == null) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Image(
            image: widget.image.image,
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: CropGrid(
                crop: currentCrop,
                gridcolor: widget.gridColor,
                cornerSize: widget.gridCornerSize,
                thinWidth: widget.gridThinWidth,
                thickWidth: widget.gridThickWidth,
                scrimColor: widget.scrimColor,
                alwaysShowThirdLines: widget.alwaysShowThirdLines,
                isMoving: panStart != null,
                onSize: (size) => this.size = size,
              ),
            ),
          )
        ],
      );

  void onPanStart(DragStartDetails details) {
    if (panStart == null) {
      final type = hitTest(details.localPosition);
      if (type != _CornerTypes.None) {
        var basePoint = gridCorners[(type == _CornerTypes.Move) ? _CornerTypes.UpperLeft : type]!;
        setState(() {
          panStart = _TouchPoint(type, details.localPosition - basePoint);
        });
      }
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (panStart != null) {
      if (panStart!.type == _CornerTypes.Move)
        moveArea(details.localPosition - panStart!.offset);
      else
        moveCorner(panStart!.type, details.localPosition - panStart!.offset);
      widget.onCrop?.call(controller.crop);
    }
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      panStart = null;
    });
  }

  void onChange() {
    setState(() {
      currentCrop = controller.crop;
    });
  }

  _CornerTypes hitTest(Offset point) {
    for (final gridCorner in gridCorners.entries) {
      final area = Rect.fromCenter(center: gridCorner.value, width: 2 * widget.gridCornerSize, height: 2 * widget.gridCornerSize);
      if (area.contains(point)) return gridCorner.key;
    }

    final area = Rect.fromPoints(gridCorners[_CornerTypes.UpperLeft]!, gridCorners[_CornerTypes.LowerRight]!);
    return area.contains(point) ? _CornerTypes.Move : _CornerTypes.None;
  }

  void moveArea(Offset point) {
    final crop = controller.crop.multiply(size);
    controller.crop = Rect.fromLTWH(
      point.dx.clamp(0, size.width - crop.width),
      point.dy.clamp(0, size.height - crop.height),
      crop.width,
      crop.height,
    ).divide(size);
  }

  void moveCorner(_CornerTypes type, Offset point) {
    final crop = controller.crop.multiply(size);
    var left = crop.left;
    var top = crop.top;
    var right = crop.right;
    var bottom = crop.bottom;

    switch (type) {
      case _CornerTypes.UpperLeft:
        left = point.dx.clamp(0, right - widget.minimumImageSize);
        top = point.dy.clamp(0, bottom - widget.minimumImageSize);
        break;
      case _CornerTypes.UpperRight:
        right = point.dx.clamp(left + widget.minimumImageSize, size.width);
        top = point.dy.clamp(0, bottom - widget.minimumImageSize);
        break;
      case _CornerTypes.LowerRight:
        right = point.dx.clamp(left + widget.minimumImageSize, size.width);
        bottom = point.dy.clamp(top + widget.minimumImageSize, size.height);
        break;
      case _CornerTypes.LowerLeft:
        left = point.dx.clamp(0, right - widget.minimumImageSize);
        bottom = point.dy.clamp(top + widget.minimumImageSize, size.height);
        break;
      default:
        assert(false);
    }

    if (controller.aspectRatio != null) {
      final width = right - left;
      final height = bottom - top;
      if (width / height > controller.aspectRatio!) {
        switch (type) {
          case _CornerTypes.UpperLeft:
          case _CornerTypes.LowerLeft:
            left = right - height * controller.aspectRatio!;
            break;
          case _CornerTypes.UpperRight:
          case _CornerTypes.LowerRight:
            right = left + height * controller.aspectRatio!;
            break;
          default:
            assert(false);
        }
      } else {
        switch (type) {
          case _CornerTypes.UpperLeft:
          case _CornerTypes.UpperRight:
            top = bottom - width / controller.aspectRatio!;
            break;
          case _CornerTypes.LowerRight:
          case _CornerTypes.LowerLeft:
            bottom = top + width / controller.aspectRatio!;
            break;
          default:
            assert(false);
        }
      }
    }

    controller.crop = Rect.fromLTRB(left, top, right, bottom).divide(size);
  }
}

class _TouchPoint {
  final _CornerTypes type;
  final Offset offset;

  _TouchPoint(this.type, this.offset);
}
