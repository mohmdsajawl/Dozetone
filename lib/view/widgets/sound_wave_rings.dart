import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';

/// Custom painter that draws expanding sound wave outline rings.
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

/// Continuous pulsing Sound Wave Loader widget for the Scanning state.
///
/// Replaces standard circular progress indicators with the signature
/// expanding acoustic rings emanating from the Dozetone brand mark.
class SoundWavePulseLoader extends StatefulWidget {
  final double size;

  const SoundWavePulseLoader({
    super.key,
    this.size = 80.0,
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
    // Continuous 2.4s cycle for seamless looping pulse
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseDiameter = widget.size * 1.1;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Three staggered rings (spaced by 0.28 normalized progress)
        final p1 = t;
        final p2 = (t - 0.28) < 0 ? (t - 0.28 + 1.0) : (t - 0.28);
        final p3 = (t - 0.56) < 0 ? (t - 0.56 + 1.0) : (t - 0.56);

        return SizedBox(
          width: widget.size * 2.8,
          height: widget.size * 2.8,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Ripple rings in the background
              CustomPaint(
                size: Size(widget.size * 2.8, widget.size * 2.8),
                painter: SoundWaveRingsPainter(
                  progress1: p1,
                  progress2: p2,
                  progress3: p3,
                  baseDiameter: baseDiameter,
                  ringColor: AppColors.accent,
                ),
              ),

              // Central brand mark container
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 16.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: SvgPicture.asset(
                  AppAssets.markSvg,
                  colorFilter: const ColorFilter.mode(
                    AppColors.accent,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
