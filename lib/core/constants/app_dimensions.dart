import 'package:flutter/material.dart';

/// Layout dimension tokens, spacings, sizes, and corner radii.
///
/// Ensures no magic numbers exist in widgets.
abstract final class AppDimensions {
  // Spacing scale (4, 8, 12, 16, 24, 32)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Corner radii (12, 24, 28, 999)
  static const double radiusCard = 12.0;
  static const double radiusArtworkSmall = 12.0;
  static const double radiusArtworkLarge = 24.0;
  static const double radiusBottomSheetTop = 28.0;
  static const double radiusPill = 999.0;

  // Border radius helpers
  static final BorderRadius borderRadiusCard = BorderRadius.circular(radiusCard);
  static final BorderRadius borderRadiusArtworkSmall = BorderRadius.circular(radiusArtworkSmall);
  static final BorderRadius borderRadiusArtworkLarge = BorderRadius.circular(radiusArtworkLarge);
  static const BorderRadius borderRadiusBottomSheet = BorderRadius.vertical(
    top: Radius.circular(radiusBottomSheetTop),
  );
  static final BorderRadius borderRadiusPill = BorderRadius.circular(radiusPill);

  // Component heights and touch target sizes
  static const double minTouchTarget = 48.0;
  static const double listRowHeight = 72.0;
  static const double listArtSize = 48.0;
  static const double miniPlayerHeight = 64.0;
  static const double mainPlayButtonSize = 72.0;
  static const double miniPlayProgressHeight = 2.0;
  static const double logoHeaderHeight = 24.0;
  static const double splashMarkWidth = 96.0;
}
