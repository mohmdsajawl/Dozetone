import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated music equalizer lines widget.
///
/// Displays vertical dancing bars that visualize active audio playback.
/// When [isPlaying] is false, bars gently settle at resting heights.
class MusicWaveBars extends StatefulWidget {
  /// Whether the track is actively playing.
  final bool isPlaying;

  /// Color of the equalizer bars (defaults to [AppColors.accent]).
  final Color color;

  /// Total width of the equalizer container.
  final double width;

  /// Maximum height of the equalizer bars.
  final double height;

  /// Number of bars in the equalizer (defaults to 5).
  final int barCount;

  /// Width of each bar (defaults to 2.4).
  final double barWidth;

  /// Spacing between bars (defaults to 1.8).
  final double gap;

  const MusicWaveBars({
    super.key,
    this.isPlaying = true,
    this.color = AppColors.accent,
    this.width = 22.0,
    this.height = 18.0,
    this.barCount = 5,
    this.barWidth = 2.4,
    this.gap = 1.8,
  });

  @override
  State<MusicWaveBars> createState() => _MusicWaveBarsState();
}

class _MusicWaveBarsState extends State<MusicWaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MusicWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const minHeight = 3.5;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (index) {
              double barHeight;

              if (widget.isPlaying) {
                final phase = (index * (1.0 / widget.barCount)) * 2 * math.pi;
                final wave = (math.sin(progress * 2 * math.pi + phase) + 1.0) / 2.0;
                barHeight = minHeight + wave * (widget.height - minHeight);
              } else {
                barHeight = switch (index % 4) {
                  0 => 4.0,
                  1 => 7.0,
                  2 => 9.0,
                  _ => 5.0,
                };
              }

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.barCount - 1 ? widget.gap : 0.0,
                ),
                child: Container(
                  width: widget.barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: widget.isPlaying
                        ? <BoxShadow>[
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.35),
                              blurRadius: 3.0,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// A full-width animated equalizer soundwave visualizer for the Now Playing screen.
class SoundwaveVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final int barCount;
  final Color? activeColor;
  final Color? inactiveColor;

  const SoundwaveVisualizer({
    super.key,
    required this.isPlaying,
    this.height = 24.0,
    this.barCount = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SoundwaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? AppColors.accent;
    final inactive = widget.inactiveColor ?? AppColors.outline;
    const minHeight = 4.0;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              double barHeight;

              if (widget.isPlaying) {
                final ratio = index / widget.barCount;
                final phase1 = ratio * 2 * math.pi;
                final phase2 = ratio * 4 * math.pi;
                final wave = 0.55 * math.sin(progress * 2 * math.pi + phase1) +
                    0.45 * math.cos(progress * 3 * math.pi + phase2);
                final normalized = ((wave + 1.0) / 2.0).clamp(0.0, 1.0);
                barHeight = minHeight + normalized * (widget.height - minHeight);
              } else {
                // Calm resting bell curve
                final centerDist = (index - widget.barCount / 2).abs() /
                    (widget.barCount / 2);
                barHeight = minHeight + (1.0 - centerDist) * 6.0;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 2.8,
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: widget.isPlaying
                      ? LinearGradient(
                          colors: <Color>[
                            Color.lerp(AppColors.accent, Colors.white, 0.25)!,
                            active,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: widget.isPlaying ? null : inactive,
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: widget.isPlaying
                      ? <BoxShadow>[
                          BoxShadow(
                            color: active.withValues(alpha: 0.35),
                            blurRadius: 3.0,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Overlay that positions [MusicWaveBars] centered on top of an artwork or thumbnail.
class MusicArtworkOverlay extends StatelessWidget {
  /// Whether playback is currently active.
  final bool isPlaying;

  /// Size of the artwork frame.
  final double size;

  /// Border radius matching the underlying artwork container.
  final BorderRadius borderRadius;

  /// Child widget (usually SongArtwork).
  final Widget child;

  const MusicArtworkOverlay({
    super.key,
    required this.isPlaying,
    required this.size,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        child,
        if (isPlaying)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.70),
              borderRadius: borderRadius,
            ),
            child: const Center(
              child: MusicWaveBars(
                isPlaying: true,
                color: AppColors.accent,
                width: 22.0,
                height: 18.0,
              ),
            ),
          ),
      ],
    );
  }
}
