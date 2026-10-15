import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/song.dart';
import '../../../view_model/player/player_view_model.dart';
import '../../../view_model/playlist/favorites_provider.dart';
import '../../player/widgets/add_to_playlist_modal.dart';
import 'song_artwork.dart';

/// Modal bottom sheet displaying track options and details.
///
/// Direct 1-tap options:
/// - Play Next
/// - Add to Queue
/// - Add to Playlist
/// - Favorite / Unfavorite
/// - Track Details
/// - Delete from Device
class SongOptionsModal extends ConsumerWidget {
  final Song song;
  final VoidCallback onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback onDeleteTap;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onRemoveFromFavorites;

  const SongOptionsModal({
    super.key,
    required this.song,
    required this.onPlayNext,
    this.onAddToQueue,
    required this.onDeleteTap,
    this.onRemoveFromPlaylist,
    this.onRemoveFromFavorites,
  });

  static Future<void> show({
    required BuildContext context,
    required Song song,
    required VoidCallback onPlayNext,
    VoidCallback? onAddToQueue,
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
        onAddToQueue: onAddToQueue,
        onDeleteTap: onDeleteTap,
        onRemoveFromPlaylist: onRemoveFromPlaylist,
        onRemoveFromFavorites: onRemoveFromFavorites,
      ),
    );
  }

  void _showFeedback(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.accent, size: 20.0),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  message,
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
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isFavorite = ref.watch(favoritesProvider).contains(song.id);

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
            // Standard Drag handle
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

            // 1. Play next (1-tap direct action)
            ListTile(
              leading: const Icon(
                Icons.playlist_play_rounded,
                color: AppColors.accent,
                size: 24.0,
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

            // 2. Add to queue (1-tap direct action)
            ListTile(
              leading: const Icon(
                Icons.queue_music_rounded,
                color: AppColors.accent,
                size: 24.0,
              ),
              title: Text(
                l10n.addToQueue,
                style: AppTextStyles.body,
              ),
              onTap: () {
                Navigator.of(context).pop();
                if (onAddToQueue != null) {
                  onAddToQueue!();
                } else {
                  ref.read(playerViewModelProvider.notifier).addToQueue(song);
                  _showFeedback(
                    context,
                    'Added to queue: ${song.title}',
                    Icons.queue_music_rounded,
                  );
                }
              },
            ),

            // 3. Add to playlist... (opens clean playlist selector)
            ListTile(
              leading: const Icon(
                Icons.playlist_add_rounded,
                color: AppColors.accent,
                size: 24.0,
              ),
              title: Text(
                l10n.addToPlaylist,
                style: AppTextStyles.body,
              ),
              onTap: () {
                Navigator.of(context).pop();
                AddToPlaylistModal.show(
                  context: context,
                  song: song,
                  showFavorites: false,
                );
              },
            ),

            // 4. Favorites toggle
            if (onRemoveFromFavorites != null)
              ListTile(
                leading: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 24.0,
                ),
                title: Text(
                  l10n.removeFromFavorites,
                  style: AppTextStyles.body,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onRemoveFromFavorites!();
                },
              )
            else
              ListTile(
                leading: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : AppColors.accent,
                  size: 24.0,
                ),
                title: Text(
                  isFavorite ? l10n.removeFromFavorites : 'Add to Favorites',
                  style: AppTextStyles.body,
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final nowFav = await ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(song.id);
                  if (context.mounted) {
                    _showFeedback(
                      context,
                      nowFav
                          ? 'Added to Favorites'
                          : l10n.removedFromFavorites(song.title),
                      nowFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    );
                  }
                },
              ),

            // 5 (optional): Remove from playlist
            if (onRemoveFromPlaylist != null)
              ListTile(
                leading: const Icon(
                  Icons.playlist_remove_rounded,
                  color: AppColors.accent,
                  size: 24.0,
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

            // 6. Track details
            ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textSecondary,
                size: 24.0,
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

            // 7. Delete from device
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 24.0,
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
