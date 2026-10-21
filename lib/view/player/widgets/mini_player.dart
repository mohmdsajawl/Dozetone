import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_names.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../widgets/marquee_text.dart';
import '../../widgets/music_wave_bars.dart';
import 'add_to_playlist_modal.dart';
import 'playback_queue_modal.dart';
import '../../library/widgets/song_artwork.dart';
import '../../../view_model/player/player_view_model.dart';

/// Docked bottom mini player bar (64 dp) in the Library screen.
///
/// Features top progress indicator line, artwork thumbnail, track details,
/// marquee title animation, and instant play/pause control. Tapping anywhere navigates to Now Playing.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerViewModelProvider);
    final song = playerState.currentSong;
    final l10n = AppLocalizations.of(context)!;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final viewModel = ref.read(playerViewModelProvider.notifier);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space8,
          vertical: AppDimensions.space8,
        ),
        child: Container(
          height: AppDimensions.miniPlayerHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.borderRadiusCard,
            border: Border.all(color: AppColors.outline),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.35),
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

                        // Queue sheet trigger button
                        IconButton(
                          icon: const Icon(
                            Icons.queue_music_rounded,
                            size: 22.0,
                            color: AppColors.textSecondary,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(AppDimensions.space6),
                          tooltip: l10n.queueTitle,
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
                          tooltip: l10n.addToPlaylistOrFavorites,
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
      ),
    );
  }
}
