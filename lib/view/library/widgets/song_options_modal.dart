import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/song.dart';
import '../../../view_model/library/library_view_model.dart';
import '../../../view_model/player/player_view_model.dart';
import '../../../view_model/playlist/favorites_provider.dart';
import '../../player/widgets/add_to_playlist_modal.dart';
import 'song_artwork.dart';

/// Modal bottom sheet displaying track options and details.
///
/// Direct 1-tap options:
/// - Play Next (hidden if currently playing)
/// - Add to Queue (hidden if currently playing)
/// - Add to Playlist
/// - Favorite / Unfavorite
/// - Rename Song
/// - Track Details
/// - Delete from Device
class SongOptionsModal extends ConsumerWidget {
  final BuildContext parentContext;
  final Song song;
  final VoidCallback onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback onDeleteTap;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onRemoveFromFavorites;

  const SongOptionsModal({
    super.key,
    required this.parentContext,
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppDimensions.borderRadiusBottomSheet,
      ),
      builder: (modalContext) => SongOptionsModal(
        parentContext: context,
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
    final currentPlayingSong = ref.watch(playerViewModelProvider).currentSong;
    final isCurrentlyPlaying = currentPlayingSong?.id == song.id;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
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
                    dataUri: song.dataUri,
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

              // 1 & 2. Play next and Add to queue (only shown if not currently playing)
              if (!isCurrentlyPlaying) ...<Widget>[
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
                        parentContext,
                        'Added to queue: ${song.title}',
                        Icons.queue_music_rounded,
                      );
                    }
                  },
                ),
              ],

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
                    context: parentContext,
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
                    if (parentContext.mounted) {
                      _showFeedback(
                        parentContext,
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

              // 6. Rename Song
              ListTile(
                leading: const Icon(
                  Icons.drive_file_rename_outline_rounded,
                  color: AppColors.accent,
                  size: 24.0,
                ),
                title: Text(
                  l10n.renameSong,
                  style: AppTextStyles.body,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: parentContext,
                    builder: (dialogCtx) => _RenameSongDialog(
                      song: song,
                      screenContext: parentContext,
                    ),
                  );
                },
              ),

              // 7. Track details
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
                  _showTrackInfoDialog(parentContext);
                },
              ),

              // 8. Delete from device
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
                  _showDeleteConfirmationDialog(parentContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext screenContext) {
    final l10n = AppLocalizations.of(screenContext)!;

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.deleteSongTitle, style: AppTextStyles.screenTitle),
        content: Text(
          l10n.deleteSongMessage(song.title),
          style: AppTextStyles.bodySecondary,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDeleteTap();
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrackInfoDialog(BuildContext screenContext) {
    final l10n = AppLocalizations.of(screenContext)!;
    final sizeMb = (song.sizeBytes != null && song.sizeBytes! > 0)
        ? '${(song.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB'
        : 'Unknown';

    final dateAddedStr = (song.dateAdded != null && song.dateAdded! > 0)
        ? DateFormat('MMM dd, yyyy  •  hh:mm a').format(
            DateTime.fromMillisecondsSinceEpoch(song.dateAdded! * 1000),
          )
        : 'Unknown';

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: SelectableText(song.title, style: AppTextStyles.screenTitle),
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          SelectableText(
            value,
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone dialog for renaming a song.
/// Uses its own ConsumerState to guarantee ref is always active and mounted.
class _RenameSongDialog extends ConsumerStatefulWidget {
  final Song song;
  final BuildContext screenContext;

  const _RenameSongDialog({
    required this.song,
    required this.screenContext,
  });

  @override
  ConsumerState<_RenameSongDialog> createState() => _RenameSongDialogState();
}

class _RenameSongDialogState extends ConsumerState<_RenameSongDialog> {
  late final TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.song.title);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newTitle = _controller.text.trim();
    if (newTitle.isEmpty || newTitle == widget.song.title) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final l10n = AppLocalizations.of(widget.screenContext)!;
    final renamed = await ref
        .read(libraryViewModelProvider.notifier)
        .renameSong(widget.song, newTitle);

    if (renamed) {
      ref
          .read(playerViewModelProvider.notifier)
          .updateSongMetadata(widget.song.id, newTitle);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }

    if (widget.screenContext.mounted) {
      ScaffoldMessenger.of(widget.screenContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                Icon(
                  renamed
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: renamed ? AppColors.accent : AppColors.error,
                  size: 20.0,
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Text(
                    renamed
                        ? l10n.renameSongSuccess(newTitle)
                        : l10n.renameSongFailed,
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.renameSongDialogTitle,
        style: AppTextStyles.screenTitle,
      ),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          autofocus: true,
          enabled: !_isLoading,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            labelText: l10n.renameSongFieldLabel,
            labelStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent, width: 2.0),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outline),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppColors.accent,
                  ),
                )
              : Text(
                  l10n.renameSong,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
