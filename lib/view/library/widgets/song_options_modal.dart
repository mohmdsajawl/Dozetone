import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/song.dart';
import '../../player/widgets/add_to_playlist_modal.dart';
import 'song_artwork.dart';

/// Modal bottom sheet displaying track options and details.
class SongOptionsModal extends StatelessWidget {
  final Song song;
  final VoidCallback onPlayNext;
  final VoidCallback onDeleteTap;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onRemoveFromFavorites;

  const SongOptionsModal({
    super.key,
    required this.song,
    required this.onPlayNext,
    required this.onDeleteTap,
    this.onRemoveFromPlaylist,
    this.onRemoveFromFavorites,
  });

  static Future<void> show({
    required BuildContext context,
    required Song song,
    required VoidCallback onPlayNext,
    required VoidCallback onDeleteTap,
    VoidCallback? onRemoveFromPlaylist,
    VoidCallback? onRemoveFromFavorites,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppDimensions.borderRadiusBottomSheet,
      ),
      builder: (context) => SongOptionsModal(
        song: song,
        onPlayNext: onPlayNext,
        onDeleteTap: onDeleteTap,
        onRemoveFromPlaylist: onRemoveFromPlaylist,
        onRemoveFromFavorites: onRemoveFromFavorites,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.space16,
          horizontal: AppDimensions.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Drag handle
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Track header preview
            Row(
              children: <Widget>[
                SongArtwork(
                  songId: song.id,
                  albumId: song.albumId,
                  size: 54.0,
                  borderRadius: AppDimensions.borderRadiusArtworkSmall,
                ),
                const SizedBox(width: AppDimensions.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song.title,
                        style: AppTextStyles.songTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        '${song.artist}  •  ${song.formattedDuration}',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            const Divider(color: AppColors.outline, height: 1.0),
            const SizedBox(height: AppDimensions.space8),

            // Option 1: Play next
            ListTile(
              leading: const Icon(
                Icons.queue_music_rounded,
                color: AppColors.accent,
              ),
              title: Text(
                l10n.playNext,
                style: AppTextStyles.body,
              ),
              onTap: () {
                Navigator.of(context).pop();
                onPlayNext();
              },
            ),

            // Option 2: Add to... (opens AddToPlaylistModal)
            ListTile(
              leading: const Icon(
                Icons.add_to_photos_rounded,
                color: AppColors.accent,
              ),
              title: Text(
                l10n.addTo,
                style: AppTextStyles.body,
              ),
              onTap: () {
                Navigator.of(context).pop();
                AddToPlaylistModal.show(context: context, song: song);
              },
            ),

            // Option 3 (optional): Remove from favorites
            if (onRemoveFromFavorites != null)
              ListTile(
                leading: const Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.accent,
                ),
                title: Text(
                  l10n.removeFromFavorites,
                  style: AppTextStyles.body,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onRemoveFromFavorites!();
                },
              ),

            // Option 4 (optional): Remove from playlist
            if (onRemoveFromPlaylist != null)
              ListTile(
                leading: const Icon(
                  Icons.playlist_remove_rounded,
                  color: AppColors.accent,
                ),
                title: Text(
                  l10n.removeSongFromPlaylist,
                  style: AppTextStyles.body,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onRemoveFromPlaylist!();
                },
              ),

            // Option 3: Track details (with date & time)
            ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textSecondary,
              ),
              title: Text(
                l10n.songDetails,
                style: AppTextStyles.body,
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showTrackInfoDialog(context);
              },
            ),

            // Option 3: Delete from device
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: Text(
                l10n.delete,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.deleteSongTitle, style: AppTextStyles.screenTitle),
        content: Text(
          l10n.deleteSongMessage(song.title),
          style: AppTextStyles.bodySecondary,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteTap();
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrackInfoDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sizeMb = (song.sizeBytes != null && song.sizeBytes! > 0)
        ? '${(song.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB'
        : 'Unknown';

    final dateAddedStr = (song.dateAdded != null && song.dateAdded! > 0)
        ? DateFormat('MMM dd, yyyy  •  hh:mm a').format(
            DateTime.fromMillisecondsSinceEpoch(song.dateAdded! * 1000),
          )
        : 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(song.title, style: AppTextStyles.screenTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildDetailRow(l10n.dateAdded, dateAddedStr),
              _buildDetailRow('Artist', song.artist),
              if (song.album != null && song.album!.isNotEmpty)
                _buildDetailRow('Album', song.album!),
              _buildDetailRow('Duration', song.formattedDuration),
              _buildDetailRow('File Size', sizeMb),
              _buildDetailRow('Path', song.dataUri),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.accent),
          ),
          Text(
            value,
            style: AppTextStyles.bodySecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
