import 'package:flutter/material.dart';

/// Design system color tokens for Dozetone (Midnight Blue palette).
///
/// All UI colors are centralized here to guarantee consistency
/// across the entire app. Version 2 can easily swap the accent color.
abstract final class AppColors {
  /// Deep dark screen background (#0F1424).
  static const Color background = Color(0xFF0F1424);

  /// Elevated surface color for cards, sheets, and mini player (#1A2036).
  static const Color surface = Color(0xFF1A2036);

  /// Main brand accent color used for buttons and highlights (#8E9AF0).
  static const Color accent = Color(0xFF8E9AF0);

  /// Content color (text/icons) displayed directly on top of accent (#0F1424).
  static const Color onAccent = Color(0xFF0F1424);

  /// Primary high-contrast text color (#E6E8F2).
  static const Color textPrimary = Color(0xFFE6E8F2);

  /// Secondary muted text color for subtitles, artists, hints (#8A90AD).
  static const Color textSecondary = Color(0xFF8A90AD);

  /// Outline color for borders, subtle dividers, and progress track (#2A3250).
  static const Color outline = Color(0xFF2A3250);

  /// Error color for alerts, failure states, and warnings (#F28B82).
  static const Color error = Color(0xFFF28B82);

  /// Helper to generate a soft accent container background with custom opacity.
  /// Computed dynamically from accent so themes stay coherent.
  static Color softAccent([double opacity = 0.15]) {
    return accent.withValues(alpha: opacity);
  }
}
