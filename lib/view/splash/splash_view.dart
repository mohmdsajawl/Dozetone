import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/theme/app_colors.dart';
import '../../view_model/library/library_view_model.dart';
import '../widgets/sound_wave_rings.dart';

/// Animated Sound Wave Splash screen (Stage 2).
///
/// Implements the exact 2.8s choreographed timeline from requirements:
/// - 0.00 to 0.44s: D fades in (0 to 1) and scales (0.9 to 1.0)
/// - 0.44 to 0.60s: Button press compression (scale 1.0 to 0.86)
/// - 0.60 to 0.83s: Release rebound (scale 0.86 to 1.05)
/// - 0.83 to 1.10s: Settle back to 1.0
/// - Sound wave ripples: 3 rings starting at 0.60s staggered by 0.3s
/// - At ~2.6s: Navigates to Library with crossfade transition
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.splashTotal,
    );

    // Warm up the library scanning in the background while splash plays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryViewModelProvider.notifier).initialize();
      _startSplashSequence();
    });
  }

  void _startSplashSequence() {
    // Check system accessibility reduce-motion setting
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      // Respect accessibility: show static D for 600 ms, then navigate
      _navigationTimer = Timer(AppDurations.reduceMotionSplash, _navigateToLibrary);
      return;
    }

    // Play full signature animation
    _controller.forward();

    // Trigger navigation at 2.6 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2600), _navigateToLibrary);
  }

  void _navigateToLibrary() {
    if (!mounted) {
      return;
    }
    context.go(RouteNames.libraryPath);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dWidth = AppDimensions.splashMarkWidth;
    const baseDiameter = dWidth * 1.1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final tSec = _controller.value * 2.8;

            // 1. D Opacity: 0.00 to 0.44s
            final dOpacity = (tSec / 0.44).clamp(0.0, 1.0);

            // 2. D Scale timeline calculation
            double dScale = 1.0;
            if (tSec < 0.44) {
              final norm = (tSec / 0.44).clamp(0.0, 1.0);
              dScale = 0.9 + (0.1 * Curves.easeOut.transform(norm));
            } else if (tSec < 0.60) {
              final norm = ((tSec - 0.44) / 0.16).clamp(0.0, 1.0);
              dScale = 1.0 - (0.14 * Curves.easeIn.transform(norm)); // 1.0 to 0.86
            } else if (tSec < 0.83) {
              final norm = ((tSec - 0.60) / 0.23).clamp(0.0, 1.0);
              dScale = 0.86 + (0.19 * Curves.easeOut.transform(norm)); // 0.86 to 1.05
            } else if (tSec < 1.10) {
              final norm = ((tSec - 0.83) / 0.27).clamp(0.0, 1.0);
              dScale = 1.05 - (0.05 * Curves.easeInOut.transform(norm)); // 1.05 to 1.00
            }

            // 3. Three sound wave rings starting at 0.60s staggered by 0.3s (each 1.6s)
            final ringProgress1 = ((tSec - 0.60) / 1.6).clamp(0.0, 1.0);
            final ringProgress2 = ((tSec - 0.90) / 1.6).clamp(0.0, 1.0);
            final ringProgress3 = ((tSec - 1.20) / 1.6).clamp(0.0, 1.0);

            return SizedBox(
              width: dWidth * 3.0,
              height: dWidth * 3.0,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Sound wave rings drawn behind the D mark
                  CustomPaint(
                    size: const Size(dWidth * 3.0, dWidth * 3.0),
                    painter: SoundWaveRingsPainter(
                      progress1: ringProgress1,
                      progress2: ringProgress2,
                      progress3: ringProgress3,
                      baseDiameter: baseDiameter,
                      ringColor: AppColors.accent,
                    ),
                  ),

                  // Animated D mark in center
                  Transform.scale(
                    scale: dScale,
                    child: Opacity(
                      opacity: dOpacity,
                      child: SvgPicture.asset(
                        AppAssets.markSvg,
                        width: dWidth,
                        height: dWidth,
                        colorFilter: const ColorFilter.mode(
                          AppColors.accent,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
