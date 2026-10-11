import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../model/song.dart';

/// Single item tile for displaying an audio track in the Library.
///
/// Implements 72 dp height, 48 dp artwork with 12 radius,
/// custom D-mark placeholder, and duration formatting.
class SongListTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;

  const SongListTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    required this.onTap,
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
            // Album artwork with placeholder fallback
            _buildArtwork(),
            const SizedBox(width: AppDimensions.space16),

            // Title and Artist
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
                  Text(
                    song.artist,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.space12),

            // Duration mm:ss
            Text(
              song.formattedDuration,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    return ClipRRect(
      borderRadius: AppDimensions.borderRadiusArtworkSmall,
      child: SizedBox(
        width: AppDimensions.listArtSize,
        height: AppDimensions.listArtSize,
        child: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          artworkWidth: AppDimensions.listArtSize,
          artworkHeight: AppDimensions.listArtSize,
          artworkBorder: AppDimensions.borderRadiusArtworkSmall,
          artworkQuality: FilterQuality.low,
          nullArtworkWidget: _buildArtworkPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildArtworkPlaceholder() {
    return Container(
      width: AppDimensions.listArtSize,
      height: AppDimensions.listArtSize,
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: SvgPicture.asset(
        AppAssets.markSvg,
        colorFilter: ColorFilter.mode(
          AppColors.accent.withValues(alpha: 0.5),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
