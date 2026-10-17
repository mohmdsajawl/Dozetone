import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_names.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/music_wave_bars.dart';
import 'add_to_playlist_modal.dart';
import 'playback_queue_modal.dart';
import '../../library/widgets/song_artwork.dart';
import '../../../model/sleep_timer_state.dart';
import '../../../view_model/player/player_view_model.dart';
import '../../../view_model/sleep_timer/sleep_timer_view_model.dart';

/// Docked bottom mini player bar in the Library screen.
///
/// Features top progress indicator line, artwork thumbnail, track details,
/// marquee title animation, instant play/pause control, and an integrated
/// expandable Bedtime Auto-Timer drawer that slides upwards with smooth animation.
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  Timer? _autoCollapseTimer;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _expandController.dispose();
    super.dispose();
  }

  void _triggerAutoExpand() {
    _autoCollapseTimer?.cancel();
    _expandController.forward();
    _autoCollapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _expandController.reverse();
      }
    });
  }

  void _toggleExpand() {
    _autoCollapseTimer?.cancel();
    if (_expandController.isCompleted || _expandController.value > 0.5) {
      _expandController.reverse();
    } else {
      _expandController.forward();
    }
  }

  void _collapse() {
    _autoCollapseTimer?.cancel();
    if (mounted) {
      _expandController.reverse();
    }
  }

  Widget _buildBedtimeCard(SleepTimerState sleepTimer) {
    final remainingText = sleepTimer.formattedRemaining.isNotEmpty
        ? sleepTimer.formattedRemaining
        : 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space6),
      decoration: BoxDecoration(
        color: const Color(0xFF14192B),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space8,
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppDimensions.space4),
            decoration: BoxDecoration(
              color: AppColors.softAccent(0.18),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: const Icon(
              Icons.bedtime_rounded,
              size: 16.0,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Bedtime Timer Active',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Remaining: $remainingText',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space8,
                vertical: AppDimensions.space4,
              ),
              visualDensity: VisualDensity.compact,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              ref.read(sleepTimerProvider.notifier).cancelTimer();
              _collapse();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space4),
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20.0,
              color: AppColors.textSecondary,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28.0, minHeight: 28.0),
            tooltip: 'Collapse',
            onPressed: _collapse,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerViewModelProvider);
    final song = playerState.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final sleepTimer = ref.watch(sleepTimerProvider);

    // Auto-collapse if timer becomes inactive
    if (!sleepTimer.isActive && (_expandController.isCompleted || _expandController.value > 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _collapse();
      });
    }

    // Listen to Bedtime Auto-Timer trigger to smoothly expand upwards and auto-collapse after 3s
    ref.listen<AsyncValue<Duration>>(bedtimeAutoStartStreamProvider, (previous, next) {
      next.whenData((_) {
        if (mounted) {
          _triggerAutoExpand();
        }
      });
    });

    final viewModel = ref.read(playerViewModelProvider.notifier);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space8,
          vertical: AppDimensions.space8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Expandable Bedtime Card (Smooth SizeTransition upwards)
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, _) {
                if (_expandController.value == 0 && !sleepTimer.isActive) {
                  return const SizedBox.shrink();
                }
                return SizeTransition(
                  sizeFactor: _expandAnimation,
                  alignment: Alignment.bottomCenter,
                  child: _buildBedtimeCard(sleepTimer),
                );
              },
            ),

            // Main MiniPlayer Body
            Container(
              height: AppDimensions.miniPlayerHeight,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.borderRadiusCard,
                border: Border.all(color: AppColors.outline),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  // Top 2 dp progress indicator line
                  SizedBox(
                    height: AppDimensions.miniPlayProgressHeight,
                    child: LinearProgressIndicator(
                      value: playerState.progressFraction,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),

                  // Interactive mini player body
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push(RouteNames.nowPlayingPath),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                        ),
                        child: Row(
                          children: <Widget>[
                            // Album art thumbnail with animated music equalizer overlay
                            MusicArtworkOverlay(
                              isPlaying: playerState.isPlaying,
                              size: 44.0,
                              borderRadius: BorderRadius.circular(8.0),
                              child: SongArtwork(
                                songId: song.id,
                                albumId: song.albumId,
                                dataUri: song.dataUri,
                                size: 44.0,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space12),

                            // Title with smooth Marquee effect and artist
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  MarqueeText(
                                    text: song.title,
                                    style: AppTextStyles.songTitle,
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    song.artist,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space2),

                            // Bedtime expandable indicator (only visible when sleep timer is active)
                            if (sleepTimer.isActive)
                              AnimatedBuilder(
                                animation: _expandAnimation,
                                builder: (context, _) {
                                  final isExpanded = _expandController.value > 0.5;
                                  return IconButton(
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.bedtime_rounded,
                                      size: 20.0,
                                      color: AppColors.accent,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(AppDimensions.space6),
                                    tooltip: isExpanded
                                        ? 'Collapse bedtime timer'
                                        : 'Bedtime timer: ${sleepTimer.formattedRemaining}',
                                    onPressed: _toggleExpand,
                                  );
                                },
                              ),

                            // Queue sheet trigger button
                            IconButton(
                              icon: const Icon(
                                Icons.queue_music_rounded,
                                size: 22.0,
                                color: AppColors.textSecondary,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(AppDimensions.space6),
                              tooltip: 'Queue',
                              onPressed: () => PlaybackQueueModal.show(context: context),
                            ),

                            // Add to favorites/playlist button
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 22.0,
                                color: AppColors.textSecondary,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(AppDimensions.space6),
                              tooltip: 'Add to playlist or favorites',
                              onPressed: () => AddToPlaylistModal.show(
                                context: context,
                                song: song,
                              ),
                            ),

                            // Play/Pause button
                            IconButton(
                              icon: Icon(
                                playerState.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 28.0,
                                color: AppColors.accent,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(AppDimensions.space6),
                              onPressed: viewModel.togglePlayPause,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
