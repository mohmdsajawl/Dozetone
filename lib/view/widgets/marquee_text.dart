import 'package:flutter/material.dart';

/// Smooth auto-scrolling marquee text widget.
///
/// If [text] fits within the available width, it renders as a static text.
/// If [text] overflows, it smoothly scrolls horizontally back and forth
/// with configurable pauses at each end so the user can read the full text.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration pauseDuration;
  final double pixelsPerSecond;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.pauseDuration = const Duration(milliseconds: 1400),
    this.pixelsPerSecond = 32.0,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  AnimationController? _animationController;
  Animation<double>? _animation;
  double _lastMaxScroll = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _setupAnimation(double maxScroll) {
    if ((_lastMaxScroll - maxScroll).abs() < 1.0 && _animationController != null) {
      return;
    }
    _lastMaxScroll = maxScroll;
    _animationController?.dispose();

    if (maxScroll <= 0.0) {
      _animationController = null;
      _animation = null;
      return;
    }

    // Scroll time proportional to text length
    final scrollDurationMs = ((maxScroll / widget.pixelsPerSecond) * 1000).round();
    final totalDurationMs =
        (widget.pauseDuration.inMilliseconds * 2) + (scrollDurationMs * 2);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDurationMs),
    );

    // Compute fraction milestones: pause -> scroll forward -> pause -> scroll back
    final pauseFraction =
        widget.pauseDuration.inMilliseconds / totalDurationMs;
    final scrollFraction = scrollDurationMs / totalDurationMs;

    _animation = TweenSequence<double>(<TweenSequenceItem<double>>[
      // 1. Initial pause at start
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.0),
        weight: pauseFraction,
      ),
      // 2. Smooth scroll to the end
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: maxScroll).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: scrollFraction,
      ),
      // 3. Pause at the end
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(maxScroll),
        weight: pauseFraction,
      ),
      // 4. Smooth scroll back to start
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: maxScroll, end: 0.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: scrollFraction,
      ),
    ]).animate(_animationController!);

    _animationController!.addListener(() {
      if (_scrollController.hasClients && _animation != null) {
        _scrollController.jumpTo(_animation!.value);
      }
    });

    _animationController!.repeat();
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text || widget.style != oldWidget.style) {
      _lastMaxScroll = -1.0;
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        final textWidth = textPainter.width;
        final availableWidth = constraints.maxWidth;

        // If fits comfortably, render static text
        if (textWidth <= availableWidth) {
          _animationController?.stop();
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        // Text overflows: set up marquee animation
        final maxScroll = textWidth - availableWidth + 8.0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _setupAnimation(maxScroll);
          }
        });

        return ClipRect(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        );
      },
    );
  }
}
