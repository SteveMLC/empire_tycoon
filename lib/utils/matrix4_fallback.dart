import 'dart:math' show sin, cos, pi;
import 'package:flutter/material.dart';

/// A utility class for handling Matrix4 fallbacks in environments
/// where the standard Matrix4 operations might fail.
class Matrix4Fallback {
  /// Creates a scale transform with a fallback when Matrix4 fails.
  /// Use this instead of Transform.scale for better deployment stability.
  static Widget scale({
    Key? key,
    required double scale,
    Offset? origin,
    AlignmentGeometry? alignment,
    required Widget child,
  }) {
    try {
      // Try the standard Transform.scale first
      return Transform.scale(
        key: key,
        scale: scale,
        origin: origin,
        alignment: alignment,
        child: child,
      );
    } catch (e) {
      // If Matrix4 fails, log and use manual scaling with SizedBox
      debugPrint('Matrix4 scale failed, using fallback: $e');
      
      // Find the child's intrinsic dimensions if possible
      return Builder(
        builder: (context) {
          try {
            return SizedBox(
              width: scale * (origin != null ? origin.dx * 2 : 1.0),
              height: scale * (origin != null ? origin.dy * 2 : 1.0),
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: alignment?.resolve(TextDirection.ltr) ?? Alignment.center,
                child: child,
              ),
            );
          } catch (e) {
            // Last resort fallback - just return the original child
            debugPrint('Fallback scaling also failed: $e');
            return child;
          }
        },
      );
    }
  }
  
  /// Creates a rotation transform with a fallback when Matrix4 fails.
  /// Use this instead of Transform.rotate for better deployment stability.
  static Widget rotate({
    Key? key,
    required double angle,
    Offset? origin,
    AlignmentGeometry? alignment,
    required Widget child,
  }) {
    try {
      // Try the standard Transform.rotate first
      return Transform.rotate(
        key: key,
        angle: angle,
        origin: origin,
        alignment: alignment,
        child: child,
      );
    } catch (e) {
      // If Matrix4 fails, log and use a basic child
      debugPrint('Matrix4 rotate failed, using fallback: $e');
      return child;
    }
  }
}