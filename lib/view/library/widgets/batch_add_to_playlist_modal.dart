import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../view_model/playlist/favorites_provider.dart';

/// Modal bottom sheet allowing the user to batch-add selected songs to an
/// existing playlist or create a new playlist for them.
class BatchAddToPlaylistModal extends ConsumerWidget {
  final List<int> songIds;

  const BatchAddToPlaylistModal({
    super.key,
    required this.songIds,
  });

  /// Displays the modal sheet and returns the selected/created playlist name,
  /// or null if dismissed.
  static Future<String?> show({
    required BuildContext context,
    required List<int> songIds,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) => BatchAddToPlaylistModal(songIds: songIds),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final playlistNames = playlists.keys.toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusBottomSheetTop),
        ),
        border: Border(
          top: BorderSide(color: AppColors.outline),
          left: BorderSide(color: AppColors.outline),
          right: BorderSide(color: AppColors.outline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Grab handle
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                margin: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.playlist_add_rounded,
                    color: AppColors.accent,
                    size: 24.0,
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Text(
                      'Add ${songIds.length} ${songIds.length == 1 ? "track" : "tracks"} to playlist',
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 18.0),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.outline, height: 1.0),

            // Option: Create New Playlist
            ListTile(
              leading: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.accent,
                  size: 24.0,
                ),
              ),
              title: const Text(
                'New Playlist',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
              ),
              subtitle: const Text(
                'Create a new playlist with selected tracks',
                style: AppTextStyles.caption,
              ),
              onTap: () => _handleCreateNewPlaylist(context, ref),
            ),

            const Divider(color: AppColors.outline, height: 1.0),

            // Existing Playlists List
            Flexible(
              child: playlistNames.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppDimensions.space32),
                      child: Center(
                        child: Text(
                          'No playlists yet. Tap above to create one.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: playlistNames.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: AppColors.outline,
                        height: 1.0,
                        indent: 68.0,
                      ),
                      itemBuilder: (context, index) {
                        final name = playlistNames[index];
                        final count = playlists[name]?.length ?? 0;

                        return ListTile(
                          leading: Container(
                            width: 44.0,
                            height: 44.0,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: const Icon(
                              Icons.queue_music_rounded,
                              color: AppColors.textSecondary,
                              size: 22.0,
                            ),
                          ),
                          title: Text(
                            name,
                            style: AppTextStyles.songTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '$count ${count == 1 ? "track" : "tracks"}',
                            style: AppTextStyles.caption,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                            size: 20.0,
                          ),
                          onTap: () async {
                            final notifier = ref.read(playlistsProvider.notifier);
                            await notifier.addSongsToPlaylist(name, songIds);
                            if (context.mounted) {
                              Navigator.of(context).pop(name);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateNewPlaylist(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();

    final playlistName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.outline),
        ),
        title: const Text('New Playlist', style: AppTextStyles.screenTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Enter playlist name',
            hintStyle: AppTextStyles.bodySecondary,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(dialogCtx).pop(name);
              }
            },
            child: const Text(
              'Create & Add',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (playlistName != null && playlistName.isNotEmpty) {
      final notifier = ref.read(playlistsProvider.notifier);
      final created = await notifier.createPlaylist(playlistName);
      if (created) {
        await notifier.addSongsToPlaylist(playlistName, songIds);
      }
      if (context.mounted) {
        Navigator.of(context).pop(playlistName);
      }
    }
  }
}
