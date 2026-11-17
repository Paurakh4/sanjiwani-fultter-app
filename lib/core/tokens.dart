import 'package:flutter/material.dart';

/// Formalizes the accepted v1.5.0 visual language. These values already exist
/// across the app; centralizing them keeps spacing/radii/motion consistent
/// without changing the look.
abstract final class AppTokens {
  static const gutter = 12.0;

  static const radiusCard = 24.0;
  static const radiusOverlay = 28.0;
  static const radiusField = 18.0;
  static const radiusInner = 16.0;
  static const radiusCell = 12.0;
  static const radiusPill = 999.0;

  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;

  static const sectionGap = 24.0;
  static const headerGap = 12.0;
  static const minTap = 48.0;

  static const motionFast = Duration(milliseconds: 200);
  static const motionMedium = Duration(milliseconds: 280);
  static const motionTheme = Duration(milliseconds: 350);
  static const ease = Curves.easeOutCubic;

  /// Grows a fixed-height container with the system text scale so large
  /// accessibility fonts do not overflow, capped to keep layouts sane.
  static double scaled(BuildContext context, double base, {double max = 1.6}) {
    final factor = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, max);
    return base * factor;
  }
}
