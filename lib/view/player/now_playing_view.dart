import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../model/player_state.dart';
import '../library/widgets/song_artwork.dart';
import '../../view_model/player/player_view_model.dart';
import 'widgets/playback_queue_modal.dart';

/// Full-screen Now Playing modal view.
///
/// Features large artwork (screen width - 48 dp), draggable seek bar,
/// 72 dp accent play/pause button, shuffle, repeat mode cycling,
/// swipe down to dismiss, and sleep timer trigger.
class NowPlayingView extends ConsumerStatefulWidget {
  const NowPlayingView({super.key});

  @override
  ConsumerState<NowPlayingView> createState() => _NowPlayingViewState();
}

class _NowPlayingViewState extends ConsumerState<NowPlayingView> {
  double? _dragValue;

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final secondsStr = seconds.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final playerState = ref.watch(playerViewModelProvider);
    final viewModel = ref.read(playerViewModelProvider.notifier);
    final song = playerState.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(l10n.noSongsFound, style: AppTextStyles.bodySecondary),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxByHeight = (screenHeight - 340.0).clamp(160.0, 360.0);
    final maxByWidth = (screenWidth - AppDimensions.space48).clamp(160.0, 360.0);
    final artSize = math.min(maxByHeight, maxByWidth);

    final durationMs = playerState.duration.inMilliseconds > 0
        ? playerState.duration.inMilliseconds.toDouble()
        : song.durationMs.toDouble();

    final currentPositionMs = _dragValue ??
        playerState.position.inMilliseconds.toDouble().clamp(0.0, durationMs);

    final currentPosDuration = Duration(milliseconds: currentPositionMs.round());
    final totalDuration = Duration(milliseconds: durationMs.round());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // Swipe down to dismiss
          if ((details.primaryVelocity ?? 0) > 300) {
            context.pop();
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
            child: Column(
              children: <Widget>[
                // 1. Top bar: Down arrow to close, title "Now playing"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30.0),
                      color: AppColors.textPrimary,
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      l10n.nowPlayingTitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded, size: 26.0),
                      color: AppColors.textPrimary,
                      tooltip: l10n.queueTitle,
                      onPressed: () => PlaybackQueueModal.show(context: context),
                    ),
                  ],
                ),
                const Spacer(flex: 1),

                // 2. Square Album Artwork (screen width - 48 dp, radius 24)
                Center(
                  child: Hero(
                    tag: 'artwork_${song.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AppDimensions.borderRadiusArtworkLarge,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 28.0,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SongArtwork(
                        songId: song.id,
                        albumId: song.albumId,
                        size: artSize,
                        borderRadius: AppDimensions.borderRadiusArtworkLarge,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),

                // 3. Track Title & Artist Info
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.space6),
                      Text(
                        song.artist,
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontSize: 16.0,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // 4. Draggable Seek Bar with Elapsed and Total duration
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.outline,
                    thumbColor: AppColors.accent,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                  ),
                  child: Slider(
                    value: currentPositionMs.clamp(0.0, durationMs),
                    min: 0.0,
                    max: durationMs > 0 ? durationMs : 1.0,
                    onChanged: (value) {
                      setState(() {
                        _dragValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      viewModel.seek(Duration(milliseconds: value.round()));
                      setState(() {
                        _dragValue = null;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        _formatDuration(currentPosDuration),
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        _formatDuration(totalDuration),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),

                // 5. Controls Row: Shuffle, Previous, Play/Pause (72 dp), Next, Repeat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    // Shuffle toggle
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded),
                      iconSize: 24.0,
                      color: playerState.isShuffleEnabled
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      onPressed: viewModel.toggleShuffle,
                    ),

                    // Skip previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 36.0,
                      color: AppColors.textPrimary,
                      onPressed: viewModel.skipPrevious,
                    ),

                    // Main 72 dp Play / Pause Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: viewModel.togglePlayPause,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.mainPlayButtonSize / 2,
                        ),
                        child: Container(
                          width: AppDimensions.mainPlayButtonSize,
                          height: AppDimensions.mainPlayButtonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.35),
                                blurRadius: 20.0,
                                spreadRadius: 2.0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              playerState.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 38.0,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Skip next
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 36.0,
                      color: AppColors.textPrimary,
                      onPressed: viewModel.skipNext,
                    ),

                    // Repeat mode cycle
                    IconButton(
                      icon: Icon(
                        switch (playerState.repeatMode) {
                          PlayerRepeatMode.off => Icons.repeat_rounded,
                          PlayerRepeatMode.all => Icons.repeat_rounded,
                          PlayerRepeatMode.one => Icons.repeat_one_rounded,
                        },
                      ),
                      iconSize: 24.0,
                      color: playerState.repeatMode != PlayerRepeatMode.off
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      onPressed: viewModel.cycleRepeatMode,
                    ),
                  ],
                ),
                const Spacer(flex: 1),

                // 6. Sleep Timer Button (Moon Icon)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Opens Sleep Timer bottom sheet in Phase 3
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.bedtime_rounded,
                                  color: AppColors.accent,
                                  size: 20.0,
                                ),
                                const SizedBox(width: AppDimensions.space12),
                                Expanded(
                                  child: Text(
                                    '${l10n.sleepTimer} (Phase 3)',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                    },
                    icon: const Icon(Icons.bedtime_rounded, size: 20.0),
                    label: Text(l10n.sleepTimer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.outline),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space24,
                        vertical: AppDimensions.space12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
