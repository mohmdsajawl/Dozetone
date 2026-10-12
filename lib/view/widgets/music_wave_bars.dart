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

  const MusicWaveBars({
    super.key,
    this.isPlaying = true,
    this.color = AppColors.accent,
    this.width = 18.0,
    this.height = 16.0,
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
    const barCount = 4;
    const barWidth = 2.5;
    const minHeight = 3.5;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (index) {
              double barHeight;

              if (widget.isPlaying) {
                // Stagger each bar's phase so they bounce independently like live audio
                final phase = (index * 0.28) * 2 * math.pi;
                final wave = (math.sin(progress * 2 * math.pi + phase) + 1.0) / 2.0;
                barHeight = minHeight + wave * (widget.height - minHeight);
              } else {
                // Resting heights when paused
                barHeight = switch (index) {
                  0 => 4.0,
                  1 => 7.0,
                  2 => 5.0,
                  _ => 3.5,
                };
              }

              return Container(
                width: barWidth,
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
              color: Colors.black.withValues(alpha: 0.52),
              borderRadius: borderRadius,
            ),
            child: const Center(
              child: MusicWaveBars(
                isPlaying: true,
                color: AppColors.accent,
                width: 20.0,
                height: 18.0,
              ),
            ),
          ),
      ],
    );
  }
}
