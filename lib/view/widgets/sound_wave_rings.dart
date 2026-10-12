import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Custom painter that draws expanding sound wave outline rings for the SplashView.
///
/// Draws three concentric rings expanding outwards and fading opacity,
/// perfectly matching the Dozetone acoustic ripple signature.
class SoundWaveRingsPainter extends CustomPainter {
  /// Animation progress for the first ring (0.0 to 1.0).
  final double progress1;

  /// Animation progress for the second ring (0.0 to 1.0).
  final double progress2;

  /// Animation progress for the third ring (0.0 to 1.0).
  final double progress3;

  /// Base diameter for the rings.
  final double baseDiameter;

  /// Accent outline color.
  final Color ringColor;

  SoundWaveRingsPainter({
    required this.progress1,
    required this.progress2,
    required this.progress3,
    required this.baseDiameter,
    this.ringColor = AppColors.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    _drawRing(canvas, center, progress1);
    _drawRing(canvas, center, progress2);
    _drawRing(canvas, center, progress3);
  }

  void _drawRing(Canvas canvas, Offset center, double progress) {
    if (progress <= 0.0 || progress > 1.0) {
      return;
    }

    // Scale from 0.5 to 2.8 using ease-out curve
    final curved = Curves.easeOut.transform(progress);
    final scale = 0.5 + (curved * (2.8 - 0.5));
    final radius = (baseDiameter * scale) / 2.0;

    // Fade opacity from 0.7 down to 0.0
    final opacity = (0.7 * (1.0 - curved)).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = ringColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant SoundWaveRingsPainter oldDelegate) {
    return oldDelegate.progress1 != progress1 ||
        oldDelegate.progress2 != progress2 ||
        oldDelegate.progress3 != progress3 ||
        oldDelegate.ringColor != ringColor;
  }
}

/// Painter for the spinner-sized acoustic expanding rings loader.
/// Draws concentric acoustic rings expanding from the center dot outwards and fading.
class AcousticRingsSpinnerPainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final double progress3;
  final Color ringColor;

  AcousticRingsSpinnerPainter({
    required this.progress1,
    required this.progress2,
    required this.progress3,
    this.ringColor = AppColors.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    _drawRing(canvas, center, progress1, maxRadius);
    _drawRing(canvas, center, progress2, maxRadius);
    _drawRing(canvas, center, progress3, maxRadius);

    // Subtle small center acoustic origin dot
    final dotPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, dotPaint);
  }

  void _drawRing(Canvas canvas, Offset center, double progress, double maxRadius) {
    if (progress <= 0.0 || progress > 1.0) {
      return;
    }

    final curved = Curves.easeOut.transform(progress);
    // Radius expands from center dot to outer boundary of the spinner
    final radius = 3.0 + (curved * (maxRadius - 3.0));

    // Opacity fades smoothly from 0.85 down to 0.0
    final opacity = (0.85 * (1.0 - curved)).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = ringColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant AcousticRingsSpinnerPainter oldDelegate) {
    return oldDelegate.progress1 != progress1 ||
        oldDelegate.progress2 != progress2 ||
        oldDelegate.progress3 != progress3 ||
        oldDelegate.ringColor != ringColor;
  }
}

/// Continuous pulsing Sound Wave Loader widget for the Scanning state.
///
/// Replaces standard circular progress indicators with the signature
/// expanding acoustic rings (spinner-sized, pure expanding/fading rings).
class SoundWavePulseLoader extends StatefulWidget {
  final double size;

  const SoundWavePulseLoader({
    super.key,
    this.size = 48.0,
  });

  @override
  State<SoundWavePulseLoader> createState() => _SoundWavePulseLoaderState();
}

class _SoundWavePulseLoaderState extends State<SoundWavePulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous 1.6s cycle for smooth looping pulse
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;

          // Three staggered concentric rings
          final p1 = t;
          final p2 = (t + 0.33) % 1.0;
          final p3 = (t + 0.67) % 1.0;

          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: AcousticRingsSpinnerPainter(
              progress1: p1,
              progress2: p2,
              progress3: p3,
              ringColor: AppColors.accent,
            ),
          );
        },
      ),
    );
  }
}
