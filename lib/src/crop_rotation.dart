import 'dart:math' as math;
import 'dart:ui';

/// 90 degree rotations.
enum CropRotation {
  noon,
  threeOClock,
  sixOClock,
  nineOClock,
}

extension CropRotationExtension on CropRotation {
  /// Returns the rotation in radians cw.
  double get radians {
    switch (this) {
      case CropRotation.noon:
        return 0;
      case CropRotation.threeOClock:
        return math.pi / 2;
      case CropRotation.sixOClock:
        return math.pi;
      case CropRotation.nineOClock:
        return 3 * math.pi / 2;
    }
  }

  /// Returns the rotation in degrees cw.
  int get degrees {
    switch (this) {
      case CropRotation.noon:
        return 0;
      case CropRotation.threeOClock:
        return 90;
      case CropRotation.sixOClock:
        return 180;
      case CropRotation.nineOClock:
        return 270;
    }
  }

  static CropRotation? fromDegrees(final int degrees) {
    for (final CropRotation rotation in CropRotation.values) {
      if (rotation.degrees == degrees) {
        return rotation;
      }
    }
    return null;
  }

  /// Returns the rotation rotated 90 degrees to the right.
  CropRotation get rotateRight {
    switch (this) {
      case CropRotation.noon:
        return CropRotation.threeOClock;
      case CropRotation.threeOClock:
        return CropRotation.sixOClock;
      case CropRotation.sixOClock:
        return CropRotation.nineOClock;
      case CropRotation.nineOClock:
        return CropRotation.noon;
    }
  }

  /// Returns the rotation rotated 90 degrees to the left.
  CropRotation get rotateLeft {
    switch (this) {
      case CropRotation.noon:
        return CropRotation.nineOClock;
      case CropRotation.nineOClock:
        return CropRotation.sixOClock;
      case CropRotation.sixOClock:
        return CropRotation.threeOClock;
      case CropRotation.threeOClock:
        return CropRotation.noon;
    }
  }

  /// Returns true if the rotated width is the initial height.
  bool get isTilted {
    switch (this) {
      case CropRotation.noon:
      case CropRotation.sixOClock:
        return false;
      case CropRotation.threeOClock:
      case CropRotation.nineOClock:
        return true;
    }
  }

  /// Returns the offset as rotated.
  Offset getRotatedOffset(
    final Offset offset01,
    final double noonWidth,
    final double noonHeight,
  ) {
    switch (this) {
      case CropRotation.noon:
        return Offset(
          noonWidth * offset01.dx,
          noonHeight * offset01.dy,
        );
      case CropRotation.sixOClock:
        return Offset(
          noonWidth * (1 - offset01.dx),
          noonHeight * (1 - offset01.dy),
        );
      case CropRotation.threeOClock:
        return Offset(
          noonWidth * offset01.dy,
          noonHeight * (1 - offset01.dx),
        );
      case CropRotation.nineOClock:
        return Offset(
          noonWidth * (1 - offset01.dy),
          noonHeight * offset01.dx,
        );
    }
  }
}
