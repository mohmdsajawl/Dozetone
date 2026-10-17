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
  final VoidCallback? onLongPress;
  final VoidCallback? onMoreTap;
  final bool isSelectionMode;
  final bool isSelected;

  const SongListTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    required this.onTap,
    this.onLongPress,
    this.onMoreTap,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: AppDimensions.borderRadiusCard,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppDimensions.listRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: AppDimensions.borderRadiusCard,
        ),
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
                dataUri: song.dataUri,
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

            // Trailing actions: Checkbox indicator in selection mode, 3-dots otherwise
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24.0,
                  height: 24.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.outline,
                      width: 2.0,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16.0,
                          color: AppColors.background,
                        )
                      : null,
                ),
              )
            else
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
