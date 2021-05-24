import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class CropController extends ValueNotifier<_CropControllerValue> {
  /// Aspect ratio of the image.
  double? get aspectRatio => value.aspectRatio;

  /// Set the aspect ratio of the image.
  ///
  /// Note that the [crop] rectangle will be adjusted to fit that ratio.
  set aspectRatio(double? newAspectRatio) {
    if (newAspectRatio != null)
      value = value.copyWith(aspectRatio: newAspectRatio, crop: _adjustRatio(value.crop, newAspectRatio));
    else
      value = value.copyWith(aspectRatio: newAspectRatio);
    notifyListeners();
  }

  /// Current crop rectangle of the image (percentage).
  ///
  /// [left] and [right] are normalized between 0 and 1 (full width).
  /// [top] and [bottom] are normalized between 0 and 1 (full height).
  ///
  /// See also:
  ///
  ///  * [cropSize], which represents the same rectangle in pixels.
  Rect get crop => value.crop;

  /// Set the crop rectangle of the image (percentage).
  ///
  /// [left] and [right] are normalized between 0 and 1 (full width).
  /// [top] and [bottom] are normalized between 0 and 1 (full height).
  ///
  /// Note that if the [aspectRatio] was specified, the rectangle will be adjusted to fit that ratio.
  ///
  /// See also:
  ///
  ///  * [cropSize], which represents the same rectangle in pixels.
  set crop(Rect newCrop) {
    if (value.aspectRatio != null)
      value = value.copyWith(crop: _adjustRatio(newCrop, value.aspectRatio!));
    else
      value = value.copyWith(crop: newCrop);
    notifyListeners();
  }

  /// Current crop rectangle of the image (pixels).
  ///
  /// [left], [right], [top] and [bottom] are in pixels.
  ///
  /// See also:
  ///
  ///  * [crop], which represents the same rectangle in percentage.
  Rect get cropSize => value.crop.multiply(_bitmapSize);

  /// Set the crop rectangle of the image (pixels).
  ///
  /// [left], [right], [top] and [bottom] are in pixels.
  ///
  /// See also:
  ///
  ///  * [crop], which represents the same rectangle in percentage.
  set cropSize(Rect newCropSize) {
    if (value.aspectRatio != null)
      value = value.copyWith(crop: _adjustRatio(newCropSize.divide(_bitmapSize), value.aspectRatio!));
    else
      value = value.copyWith(crop: newCropSize.divide(_bitmapSize));
    notifyListeners();
  }

  late ui.Image _bitmap;
  late Size _bitmapSize;

  @internal
  set image(ui.Image newImage) {
    _bitmap = newImage;
    _bitmapSize = Size(newImage.width.toDouble(), newImage.height.toDouble());
    aspectRatio = aspectRatio; // force adjustment
    notifyListeners();
  }

  /// A controller for a [CropImage] widget.
  ///
  /// You can provide the required [aspectRatio] and the initial [defaultCrop].
  /// If [aspectRatio] is specified, the [defaultCrop] rect will be adjusted automatically.
  ///
  /// Remember to [dispose] of the [CropController] when it's no longer needed.
  /// This will ensure we discard any resources used by the object.
  CropController({
    double? aspectRatio,
    Rect defaultCrop = const Rect.fromLTWH(0, 0, 1, 1),
  })  : assert(aspectRatio != 0, 'aspectRatio cannot be zero'),
        assert(defaultCrop.left >= 0 && defaultCrop.left <= 1, 'left should be 0..1'),
        assert(defaultCrop.right >= 0 && defaultCrop.right <= 1, 'right should be 0..1'),
        assert(defaultCrop.top >= 0 && defaultCrop.top <= 1, 'top should be 0..1'),
        assert(defaultCrop.bottom >= 0 && defaultCrop.bottom <= 1, 'bottom should be 0..1'),
        assert(defaultCrop.left < defaultCrop.right, 'left must be less than right'),
        assert(defaultCrop.top < defaultCrop.bottom, 'top must be less than bottom'),
        super(_CropControllerValue(aspectRatio, defaultCrop));

  /// Creates a controller for a [CropImage] widget from an initial [_CropControllerValue].
  CropController.fromValue(_CropControllerValue value) : super(value);

  Rect _adjustRatio(Rect rect, double aspectRatio) {
    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;
    final width = (right - left) * _bitmapSize.width;
    final height = (bottom - top) * _bitmapSize.height;

    if (width / height > aspectRatio) {
      final w = aspectRatio * height / 2 / _bitmapSize.width;
      left = rect.center.dx - w;
      right = rect.center.dx + w;
    } else {
      final h = width / aspectRatio / 2 / _bitmapSize.height;
      top = rect.center.dy - h;
      bottom = rect.center.dy + h;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Future<ui.Image> croppedBitmap({ui.FilterQuality quality = FilterQuality.high}) async {
    final pictureRecorder = ui.PictureRecorder();
    Canvas(pictureRecorder).drawImageRect(
      _bitmap,
      cropSize,
      Offset.zero & cropSize.size,
      Paint()..filterQuality = quality,
    );
    //FIXME Picture.toImage() crashes on Flutter Web with the HTML renderer. Use CanvasKit or avoid this operation for now.
    return await pictureRecorder.endRecording().toImage(cropSize.width.round(), cropSize.height.round());
  }

  Future<Image> croppedImage({ui.FilterQuality quality = FilterQuality.high}) async {
    return Image(
      image: UiImageProvider(await croppedBitmap(quality: quality)),
      fit: BoxFit.contain,
    );
  }
}

@immutable
class _CropControllerValue {
  final double? aspectRatio;
  final Rect crop;

  const _CropControllerValue(this.aspectRatio, this.crop);

  _CropControllerValue copyWith({double? aspectRatio, Rect? crop}) => _CropControllerValue(
        aspectRatio ?? this.aspectRatio,
        crop ?? this.crop,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    else
      return (other is _CropControllerValue && other.aspectRatio == aspectRatio && other.crop == crop);
  }

  @override
  int get hashCode => hashValues(aspectRatio.hashCode, crop.hashCode);
}

class UiImageProvider extends ImageProvider<UiImageProvider> {
  final ui.Image image;

  const UiImageProvider(this.image);

  @override
  Future<UiImageProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture<UiImageProvider>(this);

  @override
  ImageStreamCompleter load(UiImageProvider key, DecoderCallback decode) => OneFrameImageStreamCompleter(_loadAsync(key));

  Future<ImageInfo> _loadAsync(UiImageProvider key) async {
    assert(key == this);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final UiImageProvider typedOther = other;
    return image == typedOther.image;
  }

  @override
  int get hashCode => image.hashCode;
}

extension RectExtensions on Rect {
  @internal
  Rect multiply(Size size) => Rect.fromLTRB(
        left * size.width,
        top * size.height,
        right * size.width,
        bottom * size.height,
      );

  @internal
  Rect divide(Size size) => Rect.fromLTRB(
        left / size.width,
        top / size.height,
        right / size.width,
        bottom / size.height,
      );
}
