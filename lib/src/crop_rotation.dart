import 'dart:math' as math;
import 'dart:ui';

/// 90 degree rotations.
enum CropRotation {
  up,
  right,
  down,
  left,
}

extension CropRotationExtension on CropRotation {
  /// Returns the rotation in radians cw.
  double get radians {
    switch (this) {
      case CropRotation.up:
        return 0;
      case CropRotation.right:
        return math.pi / 2;
      case CropRotation.down:
        return math.pi;
      case CropRotation.left:
        return 3 * math.pi / 2;
    }
  }

  /// Returns the rotation in degrees cw.
  int get degrees {
    switch (this) {
      case CropRotation.up:
        return 0;
      case CropRotation.right:
        return 90;
      case CropRotation.down:
        return 180;
      case CropRotation.left:
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
      case CropRotation.up:
        return CropRotation.right;
      case CropRotation.right:
        return CropRotation.down;
      case CropRotation.down:
        return CropRotation.left;
      case CropRotation.left:
        return CropRotation.up;
    }
  }

  /// Returns the rotation rotated 90 degrees to the left.
  CropRotation get rotateLeft {
    switch (this) {
      case CropRotation.up:
        return CropRotation.left;
      case CropRotation.left:
        return CropRotation.down;
      case CropRotation.down:
        return CropRotation.right;
      case CropRotation.right:
        return CropRotation.up;
    }
  }

  /// Returns true if the rotated width is the initial height.
  bool get isSideways {
    switch (this) {
      case CropRotation.up:
      case CropRotation.down:
        return false;
      case CropRotation.right:
      case CropRotation.left:
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
      case CropRotation.up:
        return Offset(
          noonWidth * offset01.dx,
          noonHeight * offset01.dy,
        );
      case CropRotation.down:
        return Offset(
          noonWidth * (1 - offset01.dx),
          noonHeight * (1 - offset01.dy),
        );
      case CropRotation.right:
        return Offset(
          noonWidth * offset01.dy,
          noonHeight * (1 - offset01.dx),
        );
      case CropRotation.left:
        return Offset(
          noonWidth * (1 - offset01.dy),
          noonHeight * offset01.dx,
        );
    }
  }
}
