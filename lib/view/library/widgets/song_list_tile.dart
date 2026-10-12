import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../model/song.dart';
import '../../widgets/music_wave_bars.dart';
import 'song_artwork.dart';

/// Single item tile for displaying an audio track in the Library.
///
/// Implements 72 dp height, 48 dp artwork with 12 radius,
/// artist • duration subtitle, and trailing 3-dots actions trigger.
class SongListTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const SongListTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.borderRadiusCard,
      child: Container(
        height: AppDimensions.listRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
        child: Row(
          children: <Widget>[
            // Album artwork with cached thumbnail and animated equalizer overlay
            MusicArtworkOverlay(
              isPlaying: isPlaying,
              size: AppDimensions.listArtSize,
              borderRadius: AppDimensions.borderRadiusArtworkSmall,
              child: SongArtwork(
                songId: song.id,
                albumId: song.albumId,
                size: AppDimensions.listArtSize,
                borderRadius: AppDimensions.borderRadiusArtworkSmall,
              ),
            ),
            const SizedBox(width: AppDimensions.space16),

            // Title and Subtitle (Artist • Duration)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (isPlaying) ...<Widget>[
                        const Icon(
                          Icons.volume_up_rounded,
                          size: 16.0,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppDimensions.space4),
                      ],
                      Expanded(
                        child: Text(
                          song.title,
                          style: isPlaying
                              ? AppTextStyles.songTitleActive
                              : AppTextStyles.songTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          song.artist,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '  •  ${song.formattedDuration}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.space8),

            // Trailing 3-dots more actions button
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              iconSize: 20.0,
              color: AppColors.textSecondary,
              splashRadius: 20.0,
              onPressed: onMoreTap,
            ),
          ],
        ),
      ),
    );
  }
}
