import 'package:flutter/material.dart';

extension RectExtensions on Rect {
  Rect multiply(Size size) => Rect.fromLTRB(
        left * size.width,
        top * size.height,
        right * size.width,
        bottom * size.height,
      );

  Rect divide(Size size) => Rect.fromLTRB(
        left / size.width,
        top / size.height,
        right / size.width,
        bottom / size.height,
      );
}
