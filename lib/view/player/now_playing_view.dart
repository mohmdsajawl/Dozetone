import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../model/player_state.dart';
import '../../view_model/library/library_view_model.dart';
import '../../view_model/player/player_view_model.dart';
import '../../view_model/playlist/favorites_provider.dart';
import '../../view_model/sleep_timer/sleep_timer_view_model.dart';
import '../library/widgets/song_artwork.dart';
import '../library/widgets/song_options_modal.dart';
import '../widgets/marquee_text.dart';
import '../widgets/music_wave_bars.dart';
import 'widgets/playback_queue_modal.dart';
import 'widgets/sleep_timer_modal.dart';

/// Full-screen Now Playing modal view.
///
/// Features:
/// - Atmospheric ambient radial glow background
/// - Breathing artwork with dynamic scale and glowing drop shadow (Apple Music style)
/// - Title & artist with 1-tap interactive animated Favorite heart
/// - Top bar with Queue trigger and 3-dots More Options sheet
/// - Custom pill seek slider with smooth scrub feedback
/// - Dual-tone gradient 72 dp play/pause button with tactile feedback
/// - Shuffle and repeat buttons with active indicator dots
/// - Translucent glassmorphic sleep timer pill capsule
/// - Vertical drag to dismiss
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
    final sleepTimerState = ref.watch(sleepTimerProvider);
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

    final isFavorite = ref.watch(favoritesProvider).contains(song.id);

    ref.listen<PlayerState>(playerViewModelProvider, (previous, next) {
      if (next.currentSong == null && context.mounted) {
        context.pop();
      }
    });


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
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // Swipe down to dismiss
          if ((details.primaryVelocity ?? 0) > 300) {
            context.pop();
          }
        },
        child: Stack(
          children: <Widget>[
            // 1. Ambient Background Lighting / Aura
            Positioned(
              top: -40.0,
              left: screenWidth * 0.12,
              right: screenWidth * 0.12,
              height: 380.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      AppColors.accent.withValues(
                        alpha: playerState.isPlaying ? 0.18 : 0.08,
                      ),
                      AppColors.accent.withValues(
                        alpha: playerState.isPlaying ? 0.05 : 0.02,
                      ),
                      Colors.transparent,
                    ],
                    stops: const <double>[0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Main Foreground Layout
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space24,
                ),
                child: Column(
                  children: <Widget>[
                    // Top Bar: Dismiss, Playing Pill with Wave Bars, and Actions (Queue & More)
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.space8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          // Circular frosted dismiss button
                          Container(
                            width: 42.0,
                            height: 42.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface.withValues(alpha: 0.6),
                              border: Border.all(
                                color: AppColors.outline.withValues(alpha: 0.6),
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 28.0,
                              ),
                              color: AppColors.textPrimary,
                              tooltip: 'Dismiss',
                              onPressed: () => context.pop(),
                            ),
                          ),

                          // Center Playing Badge with dynamic mini wave bars (box-shaped matching Set Timer button)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space12,
                              vertical: AppDimensions.space6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: AppColors.surface.withValues(alpha: 0.6),
                              border: Border.all(
                                color: AppColors.outline.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                MusicWaveBars(
                                  isPlaying: playerState.isPlaying,
                                  width: 14.0,
                                  height: 11.0,
                                  barCount: 4,
                                  barWidth: 2.0,
                                  gap: 1.5,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: AppDimensions.space8),
                                Text(
                                  l10n.nowPlayingTitle.toUpperCase(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    fontSize: 11.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right actions: Queue and 3-dots
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                width: 42.0,
                                height: 42.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface.withValues(alpha: 0.6),
                                  border: Border.all(
                                    color: AppColors.outline.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.queue_music_rounded,
                                    size: 21.0,
                                  ),
                                  color: AppColors.textPrimary,
                                  tooltip: l10n.queueTitle,
                                  onPressed: () =>
                                      PlaybackQueueModal.show(context: context),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space8),
                              Container(
                                width: 42.0,
                                height: 42.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface.withValues(alpha: 0.6),
                                  border: Border.all(
                                    color: AppColors.outline.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 21.0,
                                  ),
                                  color: AppColors.textPrimary,
                                  tooltip: 'More options',
                                  onPressed: () => SongOptionsModal.show(
                                    context: context,
                                    song: song,
                                    onPlayNext: () => viewModel.insertNext(song),
                                    onAddToQueue: () => viewModel.addToQueue(song),
                                    onDeleteTap: () async {
                                      final deleted = await ref
                                          .read(libraryViewModelProvider.notifier)
                                          .deleteSong(song);

                                      if (!context.mounted) return;

                                      if (deleted) {
                                        await viewModel
                                            .removeSongFromPlayback(song.id);
                                        if (!context.mounted) return;

                                        final current = ref
                                            .read(playerViewModelProvider)
                                            .currentSong;
                                        if (current == null) {
                                          context.pop();
                                        }

                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: <Widget>[
                                                  const Icon(
                                                    Icons.check_circle_rounded,
                                                    color: AppColors.accent,
                                                    size: 20.0,
                                                  ),
                                                  const SizedBox(
                                                    width: AppDimensions.space12,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      l10n.songDeleted(song.title),
                                                      style: AppTextStyles.body.copyWith(
                                                        color: AppColors.textPrimary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: <Widget>[
                                                  const Icon(
                                                    Icons.error_outline_rounded,
                                                    color: AppColors.error,
                                                    size: 20.0,
                                                  ),
                                                  const SizedBox(
                                                    width: AppDimensions.space12,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      l10n.songDeleteFailed(
                                                          song.title),
                                                      style: AppTextStyles.body.copyWith(
                                                        color: AppColors.textPrimary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),

                    // Square Album Artwork with Apple-Music-style breathing scale & glow
                    Center(
                      child: AnimatedScale(
                        scale: playerState.isPlaying ? 1.0 : 0.92,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: AppDimensions.borderRadiusArtworkLarge,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1.0,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.accent.withValues(
                                  alpha: playerState.isPlaying ? 0.28 : 0.08,
                                ),
                                blurRadius: playerState.isPlaying ? 40.0 : 20.0,
                                offset: Offset(0, playerState.isPlaying ? 16 : 8),
                                spreadRadius: playerState.isPlaying ? 4.0 : 0.0,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 28.0,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'artwork_${song.id}',
                            child: ClipRRect(
                              borderRadius: AppDimensions.borderRadiusArtworkLarge,
                              child: SongArtwork(
                                songId: song.id,
                                albumId: song.albumId,
                                dataUri: song.dataUri,
                                size: artSize,
                                borderRadius:
                                    AppDimensions.borderRadiusArtworkLarge,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),

                    // Track Title, Artist & Interactive Favorite Heart
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                MarqueeText(
                                  text: song.title,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.space4),
                                Text(
                                  song.artist,
                                  style: AppTextStyles.bodySecondary.copyWith(
                                    fontSize: 14.0,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),

                          // Animated Favorite Button with frosted container
                          Container(
                            width: 44.0,
                            height: 44.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFavorite
                                  ? Colors.redAccent.withValues(alpha: 0.12)
                                  : AppColors.surface.withValues(alpha: 0.5),
                              border: Border.all(
                                color: isFavorite
                                    ? Colors.redAccent.withValues(alpha: 0.3)
                                    : AppColors.outline.withValues(alpha: 0.5),
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(scale: animation, child: child),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  key: ValueKey<bool>(isFavorite),
                                  color: isFavorite
                                      ? Colors.redAccent
                                      : AppColors.textSecondary,
                                  size: 24.0,
                                ),
                              ),
                              tooltip: isFavorite
                                  ? 'Remove from Favorites'
                                  : 'Add to Favorites',
                              onPressed: () async {
                                final nowFav = await ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(song.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: <Widget>[
                                            Icon(
                                              nowFav
                                                  ? Icons.favorite_rounded
                                                  : Icons.favorite_border_rounded,
                                              color: nowFav
                                                  ? Colors.redAccent
                                                  : AppColors.accent,
                                              size: 20.0,
                                            ),
                                            const SizedBox(
                                              width: AppDimensions.space12,
                                            ),
                                            Expanded(
                                              child: Text(
                                                nowFav
                                                    ? 'Added to Favorites'
                                                    : l10n.removedFromFavorites(
                                                        song.title,
                                                      ),
                                                style:
                                                    AppTextStyles.body.copyWith(
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
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Custom Pill Seek Bar with elapsed & remaining time
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4.5,
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor:
                            AppColors.outline.withValues(alpha: 0.8),
                        thumbColor: AppColors.textPrimary,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.5,
                          elevation: 3.0,
                        ),
                        overlayColor: AppColors.accent.withValues(alpha: 0.2),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 15.0),
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
                          viewModel.seek(
                            Duration(milliseconds: value.round()),
                          );
                          setState(() {
                            _dragValue = null;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _formatDuration(currentPosDuration),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _formatDuration(totalDuration),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),

                    // Controls Row: Shuffle, Previous, Gradient Play/Pause, Next, Repeat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        // Shuffle with active dot indicator
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.shuffle_rounded),
                              iconSize: 24.0,
                              color: playerState.isShuffleEnabled
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              tooltip: 'Shuffle',
                              onPressed: viewModel.toggleShuffle,
                            ),
                            Container(
                              width: 4.0,
                              height: 4.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: playerState.isShuffleEnabled
                                    ? AppColors.accent
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),

                        // Skip previous
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          iconSize: 38.0,
                          color: AppColors.textPrimary,
                          tooltip: 'Previous',
                          onPressed: viewModel.skipPrevious,
                        ),

                        // Main 72 dp Play/Pause button with dual-tone gradient & aura
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
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color.lerp(
                                      AppColors.accent,
                                      Colors.white,
                                      0.2,
                                    )!,
                                    AppColors.accent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha:
                                          playerState.isPlaying ? 0.45 : 0.25,
                                    ),
                                    blurRadius: 22.0,
                                    spreadRadius: 2.0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  playerState.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 40.0,
                                  color: AppColors.background,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Skip next
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 38.0,
                          color: AppColors.textPrimary,
                          tooltip: 'Next',
                          onPressed: viewModel.skipNext,
                        ),

                        // Repeat mode toggle with active dot indicator
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(
                                switch (playerState.repeatMode) {
                                  PlayerRepeatMode.off => Icons.repeat_rounded,
                                  PlayerRepeatMode.all => Icons.repeat_rounded,
                                  PlayerRepeatMode.one =>
                                    Icons.repeat_one_rounded,
                                },
                              ),
                              iconSize: 24.0,
                              color:
                                  playerState.repeatMode != PlayerRepeatMode.off
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                              tooltip: 'Repeat',
                              onPressed: viewModel.cycleRepeatMode,
                            ),
                            Container(
                              width: 4.0,
                              height: 4.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: playerState.repeatMode !=
                                        PlayerRepeatMode.off
                                    ? AppColors.accent
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),

                    // Box-Shaped Sleep Timer Card Button (Matching Library Button/Card Theme)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.space16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => SleepTimerModal.show(context: context),
                          borderRadius: AppDimensions.borderRadiusCard,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space16,
                              vertical: AppDimensions.space12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppDimensions.borderRadiusCard,
                              border: Border.all(
                                color: AppColors.outline.withValues(alpha: 0.8),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 36.0,
                                  height: 36.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: sleepTimerState.isActive
                                        ? AppColors.accent.withValues(alpha: 0.25)
                                        : AppColors.accent.withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(
                                    Icons.bedtime_rounded,
                                    color: AppColors.accent,
                                    size: 19.0,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        l10n.sleepTimer,
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      Text(
                                        sleepTimerState.isActive
                                            ? (sleepTimerState.isFadingOut
                                                ? l10n.fadingOut
                                                : (sleepTimerState.isTrackBased
                                                    ? (sleepTimerState.remainingTracks <= 1
                                                        ? l10n.timerEndOfSong
                                                        : '${sleepTimerState.remainingTracks} tracks remaining')
                                                    : (sleepTimerState.isEndOfSong
                                                        ? l10n.timerEndOfSong
                                                        : '${sleepTimerState.formattedRemaining} remaining')))
                                            : 'Gentle audio fade-out',
                                        style: AppTextStyles.caption.copyWith(
                                          color: sleepTimerState.isFadingOut
                                              ? AppColors.accent
                                              : AppColors.textSecondary,
                                          fontSize: 11.5,
                                          fontWeight: sleepTimerState.isFadingOut
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.space12,
                                    vertical: AppDimensions.space6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sleepTimerState.isActive
                                        ? AppColors.accent.withValues(alpha: 0.15)
                                        : AppColors.background.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color: sleepTimerState.isActive
                                          ? AppColors.accent.withValues(alpha: 0.4)
                                          : AppColors.outline.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        sleepTimerState.isActive
                                            ? sleepTimerState.formattedRemaining
                                            : 'Set timer',
                                        style: AppTextStyles.caption.copyWith(
                                          color: sleepTimerState.isActive
                                              ? AppColors.accent
                                              : AppColors.textSecondary,
                                          fontSize: 12.0,
                                          fontWeight: sleepTimerState.isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4.0),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16.0,
                                        color: sleepTimerState.isActive
                                            ? AppColors.accent
                                            : AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
