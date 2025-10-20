import 'dart:math' as math;
import 'dart:ui' as ui;

import 'crop_controller.dart';
import 'crop_grid.dart';
import 'crop_rect.dart';
import 'crop_rotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget to crop images.
///
/// See also:
///
///  * [CropController] to control the functioning of this widget.
class CropImage extends StatefulWidget {
  /// Controls the crop values being applied.
  ///
  /// If null, this widget will create its own [CropController]. If you want to specify initial values of
  /// [aspectRatio] or [defaultCrop], you need to use your own [CropController].
  /// Otherwise, [aspectRatio] will not be enforced and the [defaultCrop] will be the full image.
  final CropController? controller;

  /// The image to be cropped.
  final Image image;

  /// The crop grid color of the outer lines.
  ///
  /// Defaults to 70% white.
  final Color gridColor;

  /// The crop grid color of the inner lines.
  ///
  /// Defaults to `gridColor`.
  final Color gridInnerColor;

  /// The crop grid color of the corner lines.
  ///
  /// Defaults to `gridColor`.
  final Color gridCornerColor;

  /// The size of the padding around the image and crop grid.
  ///
  /// Defaults to 0.
  final double paddingSize;

  /// The size of the touch area.
  ///
  /// Defaults to 50.
  final double touchSize;

  /// The size of the corner of the crop grid.
  ///
  /// Defaults to 25.
  final double gridCornerSize;

  /// The offset of the corner handles from the crop grid edges.
  ///
  /// Positive values move the corners outside the grid. Defaults to 0.
  final double cornerOffset;

  /// Whether to display the corners.
  ///
  /// Defaults to true.
  final bool showCorners;

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

  /// The maximum pixel size the crop rectangle can be grown to.
  ///
  /// Defaults to infinity.
  /// You can constrain the crop rectangle to a fixed size by setting
  /// both [minimumImageSize] and [maximumImageSize] to the same value (the width) and using
  /// the [aspectRatio] of the controller to force the other dimension (width / height).
  /// Doing so disables the display of the corners.
  final double maximumImageSize;

  /// When `true`, moves when panning beyond corners, even beyond the crop rect.
  /// When `false`, moves when panning beyond corners but inside the crop rect.
  final bool alwaysMove;

  /// An optional painter between the image and the crop grid.
  ///
  /// Could be used for special effects on the cropped area.
  final CustomPainter? overlayPainter;

  /// An optional widget between the image and the crop grid.
  ///
  /// Can be used to display any kind of widget on top of the image.
  final Widget? overlayWidget;

  /// A widget rendered when the image is not ready.
  /// Default is const CircularProgressIndicator.adaptive()
  final Widget loadingPlaceholder;

  const CropImage({
    super.key,
    this.controller,
    required this.image,
    this.gridColor = Colors.white70,
    Color? gridInnerColor,
    Color? gridCornerColor,
    this.paddingSize = 0,
    this.touchSize = 50,
    this.gridCornerSize = 25,
    this.cornerOffset = 0,
    this.showCorners = true,
    this.gridThinWidth = 2,
    this.gridThickWidth = 5,
    this.scrimColor = Colors.black54,
    this.alwaysShowThirdLines = false,
    this.onCrop,
    this.minimumImageSize = 100,
    this.maximumImageSize = double.infinity,
    this.alwaysMove = false,
    this.overlayPainter,
    this.overlayWidget,
    this.loadingPlaceholder = const CircularProgressIndicator.adaptive(),
  })  : gridInnerColor = gridInnerColor ?? gridColor,
        gridCornerColor = gridCornerColor ?? gridColor,
        assert(gridCornerSize > 0, 'gridCornerSize cannot be zero'),
        assert(touchSize > 0, 'touchSize cannot be zero'),
        assert(gridThinWidth > 0, 'gridThinWidth cannot be zero'),
        assert(gridThickWidth > 0, 'gridThickWidth cannot be zero'),
        assert(minimumImageSize > 0, 'minimumImageSize cannot be zero'),
        assert(maximumImageSize >= minimumImageSize, 'maximumImageSize cannot be less than minimumImageSize'),
        assert(cornerOffset >= 0, 'cornerOffset cannot be negative');

  @override
  State<CropImage> createState() => _CropImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(DiagnosticsProperty<CropController>('controller', controller, defaultValue: null));
    properties.add(DiagnosticsProperty<Image>('image', image));
    properties.add(DiagnosticsProperty<Color>('gridColor', gridColor));
    properties.add(DiagnosticsProperty<Color>('gridInnerColor', gridInnerColor));
    properties.add(DiagnosticsProperty<Color>('gridCornerColor', gridCornerColor));
    properties.add(DiagnosticsProperty<double>('paddingSize', paddingSize));
    properties.add(DiagnosticsProperty<double>('touchSize', touchSize));
    properties.add(DiagnosticsProperty<double>('gridCornerSize', gridCornerSize));
    properties.add(DiagnosticsProperty<double>('cornerOffset', cornerOffset));
    properties.add(DiagnosticsProperty<bool>('showCorners', showCorners));
    properties.add(DiagnosticsProperty<double>('gridThinWidth', gridThinWidth));
    properties.add(DiagnosticsProperty<double>('gridThickWidth', gridThickWidth));
    properties.add(DiagnosticsProperty<Color>('scrimColor', scrimColor));
    properties.add(DiagnosticsProperty<bool>('alwaysShowThirdLines', alwaysShowThirdLines));
    properties.add(DiagnosticsProperty<ValueChanged<Rect>>('onCrop', onCrop, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('minimumImageSize', minimumImageSize));
    properties.add(DiagnosticsProperty<double>('maximumImageSize', maximumImageSize));
    properties.add(DiagnosticsProperty<bool>('alwaysMove', alwaysMove));
  }
}

enum _CornerTypes { UpperLeft, UpperRight, LowerRight, LowerLeft, None, Move }

class _CropImageState extends State<CropImage> {
  late CropController controller;
  late ImageStream _stream;
  late ImageStreamListener _streamListener;
  var currentCrop = Rect.zero;
  var size = Size.zero;
  _TouchPoint? panStart;

  Map<_CornerTypes, Offset> get gridCorners => <_CornerTypes, Offset>{
        _CornerTypes.UpperLeft: controller.crop.topLeft.scale(size.width, size.height).translate(widget.paddingSize - widget.cornerOffset, widget.paddingSize - widget.cornerOffset),
        _CornerTypes.UpperRight: controller.crop.topRight.scale(size.width, size.height).translate(widget.paddingSize + widget.cornerOffset, widget.paddingSize - widget.cornerOffset),
        _CornerTypes.LowerRight: controller.crop.bottomRight.scale(size.width, size.height).translate(widget.paddingSize + widget.cornerOffset, widget.paddingSize + widget.cornerOffset),
        _CornerTypes.LowerLeft: controller.crop.bottomLeft.scale(size.width, size.height).translate(widget.paddingSize - widget.cornerOffset, widget.paddingSize + widget.cornerOffset),
      };

  @override
  void initState() {
    super.initState();

    controller = widget.controller ?? CropController();
    controller.addListener(onChange);
    currentCrop = controller.crop;

    _stream = widget.image.image.resolve(const ImageConfiguration());
    _streamListener = ImageStreamListener((info, _) => controller.image = info.image);
    _stream.addListener(_streamListener);
  }

  @override
  void dispose() {
    controller.removeListener(onChange);

    if (widget.controller == null) {
      controller.dispose();
    }

    _stream.removeListener(_streamListener);

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

  double _getImageRatio(final double maxWidth, final double maxHeight) => controller.getImage()!.width / controller.getImage()!.height;

  double _getWidth(final double maxWidth, final double maxHeight) {
    double imageRatio = _getImageRatio(maxWidth, maxHeight);
    final screenRatio = maxWidth / maxHeight;
    if (controller.value.rotation.isSideways) {
      imageRatio = 1 / imageRatio;
    }
    if (imageRatio > screenRatio) {
      return maxWidth;
    }
    return maxHeight * imageRatio;
  }

  double _getHeight(final double maxWidth, final double maxHeight) {
    double imageRatio = _getImageRatio(maxWidth, maxHeight);
    final screenRatio = maxWidth / maxHeight;
    if (controller.value.rotation.isSideways) {
      imageRatio = 1 / imageRatio;
    }
    if (imageRatio < screenRatio) {
      return maxHeight;
    }
    return maxWidth / imageRatio;
  }

  @override
  Widget build(BuildContext context) => Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (controller.getImage() == null) {
              return widget.loadingPlaceholder;
            }
            // we remove the borders
            final double maxWidth = constraints.maxWidth - 2 * widget.paddingSize;
            final double maxHeight = constraints.maxHeight - 2 * widget.paddingSize;
            final double width = _getWidth(maxWidth, maxHeight);
            final double height = _getHeight(maxWidth, maxHeight);
            size = Size(width, height);
            final bool showCorners = widget.showCorners && widget.minimumImageSize != widget.maximumImageSize;
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: width,
                  height: height,
                  child: CustomPaint(
                    painter: _RotatedImagePainter(
                      controller.getImage()!,
                      controller.rotation,
                    ),
                  ),
                ),
                if (widget.overlayPainter != null)
                  SizedBox(
                    width: width,
                    height: height,
                    child: CustomPaint(painter: widget.overlayPainter),
                  ),
                if (widget.overlayWidget != null)
                  SizedBox(
                    width: width,
                    height: height,
                    child: widget.overlayWidget,
                  ),
                SizedBox(
                  width: width + 2 * widget.paddingSize,
                  height: height + 2 * widget.paddingSize,
                  child: GestureDetector(
                    onPanStart: onPanStart,
                    onPanUpdate: onPanUpdate,
                    onPanEnd: onPanEnd,
                    child: CropGrid(
                      crop: currentCrop,
                      gridColor: widget.gridColor,
                      gridInnerColor: widget.gridInnerColor,
                      gridCornerColor: widget.gridCornerColor,
                      paddingSize: widget.paddingSize,
                      cornerSize: showCorners ? widget.gridCornerSize : 0,
                      cornerOffset: widget.cornerOffset,
                      thinWidth: widget.gridThinWidth,
                      thickWidth: widget.gridThickWidth,
                      scrimColor: widget.scrimColor,
                      showCorners: showCorners,
                      alwaysShowThirdLines: widget.alwaysShowThirdLines,
                      isMoving: panStart != null,
                      onSize: (size) {
                        this.size = size;
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
      final offset = details.localPosition - panStart!.offset - Offset(widget.paddingSize, widget.paddingSize);
      if (panStart!.type == _CornerTypes.Move) {
        moveArea(offset);
      } else {
        moveCorner(panStart!.type, offset);
      }
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
      final area = Rect.fromCenter(center: gridCorner.value, width: widget.touchSize, height: widget.touchSize);
      if (area.contains(point)) {
        return gridCorner.key;
      }
    }

    if (widget.alwaysMove) {
      return _CornerTypes.Move;
    }

    final area = Rect.fromPoints(gridCorners[_CornerTypes.UpperLeft]!, gridCorners[_CornerTypes.LowerRight]!);
    return area.contains(point) ? _CornerTypes.Move : _CornerTypes.None;
  }

  void moveArea(Offset point) {
    final crop = controller.crop.multiply(size);
    final maxX = math.max(0.0, size.width - crop.width);
    final maxY = math.max(0.0, size.height - crop.height);
    controller.crop = Rect.fromLTWH(
      point.dx.clamp(0.0, maxX),
      point.dy.clamp(0.0, maxY),
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
    double minX, maxX;
    double minY, maxY;

    switch (type) {
      case _CornerTypes.UpperLeft:
        minX = math.max(0, right - widget.maximumImageSize);
        maxX = right - widget.minimumImageSize;
        if (minX <= maxX) {
          left = point.dx.clamp(minX, maxX);
        }
        minY = math.max(0, bottom - widget.maximumImageSize);
        maxY = bottom - widget.minimumImageSize;
        if (minY <= maxY) {
          top = point.dy.clamp(minY, maxY);
        }
        break;
      case _CornerTypes.UpperRight:
        minX = left + widget.minimumImageSize;
        maxX = math.min(left + widget.maximumImageSize, size.width);
        if (minX <= maxX) {
          right = point.dx.clamp(minX, maxX);
        }
        minY = math.max(0, bottom - widget.maximumImageSize);
        maxY = bottom - widget.minimumImageSize;
        if (minY <= maxY) {
          top = point.dy.clamp(minY, maxY);
        }
        break;
      case _CornerTypes.LowerRight:
        minX = left + widget.minimumImageSize;
        maxX = math.min(left + widget.maximumImageSize, size.width);
        if (minX <= maxX) {
          right = point.dx.clamp(minX, maxX);
        }
        minY = top + widget.minimumImageSize;
        maxY = math.min(top + widget.maximumImageSize, size.height);
        if (minY <= maxY) {
          bottom = point.dy.clamp(minY, maxY);
        }
        break;
      case _CornerTypes.LowerLeft:
        minX = math.max(0, right - widget.maximumImageSize);
        maxX = right - widget.minimumImageSize;
        if (minX <= maxX) {
          left = point.dx.clamp(minX, maxX);
        }
        minY = top + widget.minimumImageSize;
        maxY = math.min(top + widget.maximumImageSize, size.height);
        if (minY <= maxY) {
          bottom = point.dy.clamp(minY, maxY);
        }
        break;
      default:
        assert(false);
    }

    //FIXME: does not work with non-straight "rotation"
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

// FIXME: shouldn't be repainted each time the grid moves, should it?
class _RotatedImagePainter extends CustomPainter {
  _RotatedImagePainter(this.image, this.rotation);

  final ui.Image image;
  final CropRotation rotation;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    double targetWidth = size.width;
    double targetHeight = size.height;
    double offset = 0;
    if (rotation != CropRotation.up) {
      if (rotation.isSideways) {
        final double tmp = targetHeight;
        targetHeight = targetWidth;
        targetWidth = tmp;
        offset = (targetWidth - targetHeight) / 2;
        if (rotation == CropRotation.left) {
          offset = -offset;
        }
      }
      canvas.save();
      canvas.translate(targetWidth / 2, targetHeight / 2);
      canvas.rotate(rotation.radians);
      canvas.translate(-targetWidth / 2, -targetHeight / 2);
    }
    _paint.filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offset, offset, targetWidth, targetHeight),
      _paint,
    );
    if (rotation != CropRotation.up) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
