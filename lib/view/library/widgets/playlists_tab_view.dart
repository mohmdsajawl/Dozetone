import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../model/song.dart';
import '../../../view_model/library/library_state.dart';
import '../../../view_model/library/library_view_model.dart';
import '../../../view_model/player/player_view_model.dart';
import '../../../view_model/playlist/favorites_provider.dart';

import '../playlist_detail_view.dart';

/// View displaying the user's custom playlists and albums.
class PlaylistsTabView extends ConsumerWidget {
  const PlaylistsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final libraryState = ref.watch(libraryViewModelProvider);

    final allSongs = libraryState is LibraryLoaded ? libraryState.songs : <Song>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(
        top: AppDimensions.space8,
        bottom: AppDimensions.space24,
        left: AppDimensions.space16,
        right: AppDimensions.space16,
      ),
      children: <Widget>[
        // + Create New Playlist Card
        InkWell(
          onTap: () => _showCreatePlaylistDialog(context, ref),
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space16,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: const Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20.0,
                  backgroundColor: AppColors.background,
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.accent,
                    size: 24.0,
                  ),
                ),
                SizedBox(width: AppDimensions.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Create New Playlist',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        'Group songs by mood, sleep, or genre',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.space16),

        // List of user playlists
        for (final entry in playlists.entries)
          _buildPlaylistCard(
            context: context,
            ref: ref,
            name: entry.key,
            songIds: entry.value,
            allSongs: allSongs,
          ),
      ],
    );
  }

  Widget _buildPlaylistCard({
    required BuildContext context,
    required WidgetRef ref,
    required String name,
    required List<int> songIds,
    required List<Song> allSongs,
  }) {
    final playlistSongs = allSongs.where((s) => songIds.contains(s.id)).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailView(playlistName: name),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: <Widget>[
              // Playlist Icon Box
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF222B48),
                      Color(0xFF131A2D),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: AppColors.accent,
                    size: 24.0,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space16),

              // Name and Song count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${playlistSongs.length} tracks',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              // Play button
              if (playlistSongs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  iconSize: 34.0,
                  color: AppColors.accent,
                  onPressed: () {
                    ref.read(playerViewModelProvider.notifier).playSong(
                          playlistSongs.first,
                          playlistSongs,
                        );
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.accent,
                                size: 20.0,
                              ),
                              const SizedBox(width: AppDimensions.space12),
                              Expanded(
                                child: Text(
                                  'Playing playlist "$name"',
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
                ),

              // 3-dots popup options (Rename, Delete)
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                  size: 22.0,
                ),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: AppColors.outline),
                ),
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenamePlaylistDialog(context, ref, name);
                  } else if (value == 'delete') {
                    _showDeletePlaylistDialog(context, ref, name);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'rename',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.edit_rounded, color: AppColors.accent, size: 18.0),
                        SizedBox(width: AppDimensions.space12),
                        Text('Rename', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18.0),
                        SizedBox(width: AppDimensions.space12),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
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
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: AppTextStyles.caption),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final created = await ref.read(playlistsProvider.notifier).createPlaylist(name);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                Icon(
                  created ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: created ? AppColors.accent : AppColors.error,
                  size: 20.0,
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Text(
                    created
                        ? 'Created playlist "$name"'
                        : 'Playlist "$name" already exists',
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
    }
  }

  Future<void> _showRenamePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: AppColors.outline),
        ),
        title: const Text('Rename Playlist', style: AppTextStyles.screenTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Enter new playlist name',
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
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: AppTextStyles.caption),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      final success = await ref
          .read(playlistsProvider.notifier)
          .renamePlaylist(currentName, newName);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                Icon(
                  success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: success ? AppColors.accent : AppColors.error,
                  size: 20.0,
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Text(
                    success
                        ? 'Renamed to "$newName"'
                        : 'Playlist "$newName" already exists',
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
    }
  }

  Future<void> _showDeletePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: AppColors.outline),
        ),
        title: const Row(
          children: <Widget>[
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22.0),
            SizedBox(width: AppDimensions.space8),
            Text('Delete Playlist?', style: AppTextStyles.screenTitle),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"? The audio files will remain on your device.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: AppTextStyles.caption),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(playlistsProvider.notifier).deletePlaylist(name);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppColors.accent,
                  size: 20.0,
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Text(
                    'Deleted playlist "$name"',
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
    }
  }
}
