import 'dart:ui' as ui;

import 'crop_rect.dart';
import 'crop_rotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// A controller to control the functionality of [CropImage].
class CropController extends ValueNotifier<CropControllerValue> {
  /// Aspect ratio of the image (width / height).
  ///
  /// The [crop] rectangle will be adjusted to fit this ratio.
  /// Pass null for free selection clipping (aspect ratio not enforced).
  double? get aspectRatio => value.aspectRatio;

  set aspectRatio(double? newAspectRatio) {
    if (newAspectRatio != null) {
      value = value.copyWith(
        aspectRatio: newAspectRatio,
        crop: _adjustRatio(value.crop, newAspectRatio),
      );
    } else {
      value = CropControllerValue(
        null,
        value.crop,
        value.rotation,
        value.minimumImageSize,
      );
    }
    notifyListeners();
  }

  /// Current crop rectangle of the image (percentage).
  ///
  /// [left] and [right] are normalized between 0 and 1 (full width).
  /// [top] and [bottom] are normalized between 0 and 1 (full height).
  ///
  /// If the [aspectRatio] was specified, the rectangle will be adjusted to fit that ratio.
  ///
  /// See also:
  ///
  ///  * [cropSize], which represents the same rectangle in pixels.
  Rect get crop => value.crop;

  set crop(Rect newCrop) {
    if (value.aspectRatio != null) {
      value = value.copyWith(crop: _adjustRatio(newCrop, value.aspectRatio!));
    } else {
      value = value.copyWith(crop: newCrop);
    }
    notifyListeners();
  }

  CropRotation get rotation => value.rotation;

  set rotation(CropRotation rotation) {
    value = value.copyWith(rotation: rotation);
    notifyListeners();
  }

  //FIXME: should be able to deal with aspectRatio
  void rotateRight() {
    value = CropControllerValue(
      null,
      Rect.fromCenter(
        center: Offset(1 - crop.center.dy, crop.center.dx),
        width: crop.height,
        height: crop.width,
      ),
      value.rotation.rotateRight,
      value.minimumImageSize,
    );
    notifyListeners();
  }

  //FIXME: should be able to deal with aspectRatio
  void rotateLeft() {
    value = CropControllerValue(
      null,
      Rect.fromCenter(
        center: Offset(crop.center.dy, 1 - crop.center.dx),
        width: crop.height,
        height: crop.width,
      ),
      value.rotation.rotateLeft,
      value.minimumImageSize,
    );
    notifyListeners();
  }

  /// Current crop rectangle of the image (pixels).
  ///
  /// [left], [right], [top] and [bottom] are in pixels.
  ///
  /// If the [aspectRatio] was specified, the rectangle will be adjusted to fit that ratio.
  ///
  /// See also:
  ///
  ///  * [crop], which represents the same rectangle in percentage.
  Rect get cropSize => value.crop.multiply(_bitmapSize);

  set cropSize(Rect newCropSize) {
    if (value.aspectRatio != null) {
      value = value.copyWith(
          crop: _adjustRatio(
              newCropSize.divide(_bitmapSize), value.aspectRatio!));
    } else {
      value = value.copyWith(crop: newCropSize.divide(_bitmapSize));
    }
    notifyListeners();
  }

  ui.Image? _bitmap;
  late Size _bitmapSize;

  @internal
  set image(ui.Image newImage) {
    _bitmap = newImage;
    _bitmapSize = Size(newImage.width.toDouble(), newImage.height.toDouble());
    aspectRatio = aspectRatio; // force adjustment
    notifyListeners();
  }

  ui.Image? getImage() => _bitmap;

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
    CropRotation rotation = CropRotation.noon,
    double minimumImageSize = 100,
  })  : assert(aspectRatio != 0, 'aspectRatio cannot be zero'),
        assert(defaultCrop.left >= 0 && defaultCrop.left <= 1,
            'left should be 0..1'),
        assert(defaultCrop.right >= 0 && defaultCrop.right <= 1,
            'right should be 0..1'),
        assert(
            defaultCrop.top >= 0 && defaultCrop.top <= 1, 'top should be 0..1'),
        assert(defaultCrop.bottom >= 0 && defaultCrop.bottom <= 1,
            'bottom should be 0..1'),
        assert(defaultCrop.left < defaultCrop.right,
            'left must be less than right'),
        assert(defaultCrop.top < defaultCrop.bottom,
            'top must be less than bottom'),
        super(CropControllerValue(
          aspectRatio,
          defaultCrop,
          rotation,
          minimumImageSize,
        ));

  /// Creates a controller for a [CropImage] widget from an initial [CropControllerValue].
  CropController.fromValue(CropControllerValue value) : super(value);

  Rect _adjustRatio(Rect rect, double aspectRatio) {
    final width = rect.width * _bitmapSize.width;
    final height = rect.height * _bitmapSize.height;
    if (width / height > aspectRatio) {
      final w = height * aspectRatio / _bitmapSize.width;
      return Rect.fromLTWH(rect.center.dx - w / 2, rect.top, w, rect.height);
    } else {
      final h = width / aspectRatio / _bitmapSize.height;
      return Rect.fromLTWH(rect.left, rect.center.dy - h / 2, rect.width, h);
    }
  }

  /// Returns the bitmap cropped with the current crop rectangle.
  ///
  /// [maxSize] is the maximum width or height you want.
  /// You can provide the [quality] used in the resizing operation.
  /// Returns an [ui.Image] asynchronously.
  Future<ui.Image> croppedBitmap({
    final double? maxSize,
    final ui.FilterQuality quality = FilterQuality.high,
  }) async =>
      _getCroppedBitmap(
        maxSize: maxSize,
        quality: quality,
        crop: crop,
        rotation: value.rotation,
        image: _bitmap!,
      );

  /// Returns the bitmap cropped with parameters.
  ///
  /// [maxSize] is the maximum width or height you want.
  /// The [crop] `Rect` is normalized to (0, 0) x (1, 1).
  /// You can provide the [quality] used in the resizing operation.
  static Future<ui.Image> _getCroppedBitmap({
    final double? maxSize,
    final ui.FilterQuality quality = FilterQuality.high,
    required final Rect crop,
    required final CropRotation rotation,
    required final ui.Image image,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final bool tilted = rotation.isTilted;
    final double cropWidth;
    final double cropHeight;
    if (tilted) {
      cropWidth = crop.width * image.height;
      cropHeight = crop.height * image.width;
    } else {
      cropWidth = crop.width * image.width;
      cropHeight = crop.height * image.height;
    }
    // factor between the full size and the maxSize constraint.
    double factor = 1;
    if (maxSize != null) {
      if (cropWidth > maxSize || cropHeight > maxSize) {
        if (cropWidth >= cropHeight) {
          factor = maxSize / cropWidth;
        } else {
          factor = maxSize / cropHeight;
        }
      }
    }

    // just checking
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cropWidth * factor, cropHeight * factor),
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    final Offset cropCenter = rotation.getRotatedOffset(
      crop.center,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final double alternateWidth = tilted ? cropHeight : cropWidth;
    final double alternateHeight = tilted ? cropWidth : cropHeight;
    if (rotation != CropRotation.noon) {
      canvas.save();
      final double x = alternateWidth / 2 * factor;
      final double y = alternateHeight / 2 * factor;
      canvas.translate(x, y);
      canvas.rotate(rotation.radians);
      if (rotation == CropRotation.threeOClock) {
        canvas.translate(
          -y,
          -cropWidth * factor + x,
        );
      } else if (rotation == CropRotation.nineOClock) {
        canvas.translate(
          y - cropHeight * factor,
          -x,
        );
      } else if (rotation == CropRotation.sixOClock) {
        canvas.translate(-x, -y);
      }
    }

    canvas.drawImageRect(
      image,
      Rect.fromCenter(
        center: cropCenter,
        width: alternateWidth,
        height: alternateHeight,
      ),
      Rect.fromLTWH(
        0,
        0,
        alternateWidth * factor,
        alternateHeight * factor,
      ),
      Paint()..filterQuality = quality,
    );

    if (rotation != CropRotation.noon) {
      canvas.restore();
    }

    //FIXME Picture.toImage() crashes on Flutter Web with the HTML renderer. Use CanvasKit or avoid this operation for now. https://github.com/flutter/engine/pull/20750
    return await pictureRecorder
        .endRecording()
        .toImage((cropWidth * factor).round(), (cropHeight * factor).round());
  }

  /// Returns the image cropped with the current crop rectangle.
  ///
  /// You can provide the [quality] used in the resizing operation.
  /// Returns an [Image] asynchronously.
  Future<Image> croppedImage(
      {ui.FilterQuality quality = FilterQuality.high}) async {
    return Image(
      image: UiImageProvider(await croppedBitmap(quality: quality)),
      fit: BoxFit.contain,
    );
  }
}

@immutable
class CropControllerValue {
  final double? aspectRatio;
  final Rect crop;
  final CropRotation rotation;
  final double minimumImageSize;

  const CropControllerValue(
    this.aspectRatio,
    this.crop,
    this.rotation,
    this.minimumImageSize,
  );

  CropControllerValue copyWith({
    double? aspectRatio,
    Rect? crop,
    CropRotation? rotation,
    double? minimumImageSize,
  }) =>
      CropControllerValue(
        aspectRatio ?? this.aspectRatio,
        crop ?? this.crop,
        rotation ?? this.rotation,
        minimumImageSize ?? this.minimumImageSize,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CropControllerValue &&
        other.aspectRatio == aspectRatio &&
        other.crop == crop &&
        other.rotation == rotation &&
        other.minimumImageSize == minimumImageSize;
  }

  @override
  int get hashCode => Object.hash(
        aspectRatio.hashCode,
        crop.hashCode,
        rotation.hashCode,
        minimumImageSize.hashCode,
      );
}

/// Provides the given [ui.Image] object as an [Image].
///
/// Exposed as a convenience. You don't need to use it unless you want to create your own version
/// of the [croppedImage()] function of [CropController].
class UiImageProvider extends ImageProvider<UiImageProvider> {
  /// The [ui.Image] from which the image will be fetched.
  final ui.Image image;

  const UiImageProvider(this.image);

  @override
  Future<UiImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<UiImageProvider>(this);

  @override
  ImageStreamCompleter load(UiImageProvider key, DecoderCallback decode) =>
      OneFrameImageStreamCompleter(_loadAsync(key));

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
