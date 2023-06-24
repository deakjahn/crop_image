import 'dart:async';
import 'dart:ui' as ui;

import 'crop_rect.dart';
import 'crop_rotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    value = value.copyWith(crop: _adjustRatio(newCrop, value.aspectRatio));
    notifyListeners();
  }

  CropRotation get rotation => value.rotation;

  set rotation(CropRotation rotation) {
    value = value.copyWith(rotation: rotation);
    notifyListeners();
  }

  void rotateRight() => _rotate(left: false);

  void rotateLeft() => _rotate(left: true);

  void _rotate({required final bool left}) {
    final CropRotation newRotation =
        left ? value.rotation.rotateLeft : value.rotation.rotateRight;
    final Offset newCenter = left
        ? Offset(crop.center.dy, 1 - crop.center.dx)
        : Offset(1 - crop.center.dy, crop.center.dx);
    value = CropControllerValue(
      aspectRatio,
      _adjustRatio(
        Rect.fromCenter(
          center: newCenter,
          width: crop.height,
          height: crop.width,
        ),
        aspectRatio,
        rotation: newRotation,
      ),
      newRotation,
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
    value = value.copyWith(
      crop: _adjustRatio(newCropSize.divide(_bitmapSize), value.aspectRatio),
    );
    notifyListeners();
  }

  ui.Image? _bitmap;
  late Size _bitmapSize;

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
    CropRotation rotation = CropRotation.up,
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

  Rect _adjustRatio(
    Rect crop,
    double? aspectRatio, {
    CropRotation? rotation,
  }) {
    if (aspectRatio == null) {
      return crop;
    }
    final bool justRotated = rotation != null;
    rotation ??= value.rotation;
    final bitmapWidth =
        rotation.isSideways ? _bitmapSize.height : _bitmapSize.width;
    final bitmapHeight =
        rotation.isSideways ? _bitmapSize.width : _bitmapSize.height;
    if (justRotated) {
      // we've just rotated: in that case, biggest centered crop.
      const center = Offset(.5, .5);
      final width = bitmapWidth;
      final height = bitmapHeight;
      if (width / height > aspectRatio) {
        final w = height * aspectRatio / bitmapWidth;
        return Rect.fromCenter(center: center, width: w, height: 1);
      }
      final h = width / aspectRatio / bitmapHeight;
      return Rect.fromCenter(center: center, width: 1, height: h);
    }
    final width = crop.width * bitmapWidth;
    final height = crop.height * bitmapHeight;
    if (width / height > aspectRatio) {
      final w = height * aspectRatio / bitmapWidth;
      return Rect.fromLTWH(crop.center.dx - w / 2, crop.top, w, crop.height);
    } else {
      final h = width / aspectRatio / bitmapHeight;
      return Rect.fromLTWH(crop.left, crop.center.dy - h / 2, crop.width, h);
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
      getCroppedBitmap(
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
  static Future<ui.Image> getCroppedBitmap({
    final double? maxSize,
    final ui.FilterQuality quality = FilterQuality.high,
    required final Rect crop,
    required final CropRotation rotation,
    required final ui.Image image,
  }) async {
    final bool tilted = rotation.isSideways;
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

    final Offset cropCenter = rotation.getRotatedOffset(
      crop.center,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final double alternateWidth = tilted ? cropHeight : cropWidth;
    final double alternateHeight = tilted ? cropWidth : cropHeight;

    final src = Rect.fromCenter(
      center: cropCenter,
      width: alternateWidth,
      height: alternateHeight,
    );

    double destWidth = alternateWidth * factor;
    double destHeight = alternateHeight * factor;
    if (rotation == CropRotation.left || rotation == CropRotation.right) {
      destWidth = alternateHeight * factor;
      destHeight = alternateWidth * factor;
    }

    ByteData? data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    ByteData cropped = ByteData(destWidth.toInt() * destHeight.toInt() * 4);

    int srcHeight = src.bottom.toInt() - src.top.toInt();
    int srcWidth = src.right.toInt() - src.left.toInt();
    if (rotation == CropRotation.down) {
      for (int i = 0; i < destHeight.toInt(); i++) {
        for (int j = 0; j < destWidth.toInt(); j++) {
          int s =
              (destHeight.toInt() - 1 - i) * srcHeight ~/ (destHeight.toInt()) +
                  src.top.toInt();
          int t =
              (destWidth.toInt() - 1 - j) * srcWidth ~/ (destWidth.toInt()) +
                  src.left.toInt();
          cropped.setUint32((i * destWidth.toInt() + j) * 4,
              data!.getInt32((s * image.width + t) * 4));
        }
      }
    } else if (rotation == CropRotation.up) {
      for (int i = 0; i < destHeight.toInt(); i++) {
        for (int j = 0; j < destWidth.toInt(); j++) {
          int s = i * srcHeight ~/ (destHeight.toInt()) + src.top.toInt();
          int t = j * srcWidth ~/ (destWidth.toInt()) + src.left.toInt();
          cropped.setUint32((i * destWidth.toInt() + j) * 4,
              data!.getInt32((s * image.width + t) * 4));
        }
      }
    } else if (rotation == CropRotation.left) {
      for (int i = 0; i < destHeight.toInt(); i++) {
        for (int j = 0; j < destWidth.toInt(); j++) {
          int s = j * srcHeight ~/ destWidth.toInt() + src.top.toInt();
          int t = (i * -srcWidth ~/ destHeight - 1).floor() + src.right.toInt();
          cropped.setUint32((i * destWidth.toInt() + j) * 4,
              data!.getInt32((s * image.width + t) * 4));
        }
      }
    } else if (rotation == CropRotation.right) {
      for (int i = 0; i < destHeight.toInt(); i++) {
        for (int j = 0; j < destWidth.toInt(); j++) {
          int s = (-j * srcHeight / destWidth - 1).floor() + src.bottom.toInt();
          int t = i * srcWidth ~/ destHeight.toInt() + src.left.toInt();
          cropped.setUint32((i * destWidth.toInt() + j) * 4,
              data!.getInt32((s * image.width + t) * 4));
        }
      }
    }

    Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(cropped.buffer.asUint8List(), destWidth.toInt(),
        destHeight.toInt(), ui.PixelFormat.rgba8888, (result) {
      completer.complete(result);
    });
    return completer.future;
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
  ImageStreamCompleter loadImage(
          UiImageProvider key, ImageDecoderCallback decode) =>
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
