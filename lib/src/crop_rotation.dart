import 'dart:math' as math;
import 'dart:ui';

/// 90 degree rotations.
enum CropRotation {
  up,
  right,
  down,
  left,
}

/// Flip Modes, normal, inverted horizontally and vertically
enum FlipMode {
  none,
  vertical,
  horizontal,
  both
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
    final FlipMode flipMode,
    final double straightWidth,
    final double straightHeight,
  ) {
    switch (this) {
      case CropRotation.up:
        return Offset(
          straightWidth * offset01.dx,
          straightHeight * offset01.dy,
        );
      case CropRotation.down:
        return Offset(
          straightWidth * (1 - offset01.dx),
          straightHeight * (1 - offset01.dy),
        );
      case CropRotation.right:
        return Offset(
          straightWidth * offset01.dy,
          straightHeight * (1 - offset01.dx),
        );
      case CropRotation.left:
        return Offset(
          straightWidth * (1 - offset01.dy),
          straightHeight * offset01.dx,
        );
    }
  }
}
