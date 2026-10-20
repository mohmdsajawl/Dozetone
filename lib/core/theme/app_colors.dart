import 'package:flutter/material.dart';

/// Design system color tokens for Dozetone (Midnight Blue palette).
///
/// All UI colors are centralized here to guarantee consistency
/// across the entire app. Version 2 can easily swap the accent color.
abstract final class AppColors {
  /// Deep dark screen background (#0F1424).
  static const Color background = Color(0xFF0F1424);

  /// Secondary dark background for gradient headers and sheets (#131A2D).
  static const Color backgroundDark = Color(0xFF131A2D);

  /// Elevated surface color for cards, sheets, and mini player (#1A2036).
  static const Color surface = Color(0xFF1A2036);

  /// Lighter elevated surface for gradient cards and playlist covers (#222B48).
  static const Color surfaceLight = Color(0xFF222B48);

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

  /// Destructive action and active favorite heart color (#FF5252).
  static const Color favorite = Color(0xFFFF5252);

  /// Pure white for high-contrast indicators and play/pause accents (#FFFFFF).
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black for shadow and backdrop overlays (#000000).
  static const Color black = Color(0xFF000000);

  /// Standard dark modal backdrop / sheet barrier color (equivalent to black54).
  static const Color barrier = Color(0x8A000000);

  /// Dynamic artwork fallback gradients for songs without embedded album art.
  static const List<List<Color>> artworkGradients = [
    [Color(0xFF0E7490), Color(0xFF0F172A)], // Cyan to Dark Navy
    [Color(0xFF4338CA), Color(0xFF0F172A)], // Indigo to Dark Navy
    [Color(0xFF7C3AED), Color(0xFF18181B)], // Purple to Dark Void
    [Color(0xFF059669), Color(0xFF0F172A)], // Emerald to Dark Navy
    [Color(0xFFD97706), Color(0xFF1C1917)], // Amber to Charcoal
    [Color(0xFFE11D48), Color(0xFF0F172A)], // Rose to Dark Navy
  ];

  /// Helper to generate a soft accent container background with custom opacity.
  /// Computed dynamically from accent so themes stay coherent.
  static Color softAccent([double opacity = 0.15]) {
    return accent.withValues(alpha: opacity);
  }

  /// Helper to generate soft white highlight with custom opacity.
  static Color softWhite([double opacity = 0.15]) {
    return white.withValues(alpha: opacity);
  }
}
