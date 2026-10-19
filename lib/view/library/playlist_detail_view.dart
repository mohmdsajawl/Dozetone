import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../model/song.dart';
import '../../view_model/library/library_state.dart';
import '../../view_model/library/library_view_model.dart';
import '../../view_model/player/player_view_model.dart';
import '../../view_model/playlist/favorites_provider.dart';
import '../player/widgets/mini_player.dart';
import 'widgets/playlist_add_songs_sheet.dart';
import 'widgets/song_list_tile.dart';
import 'widgets/song_options_modal.dart';

/// Screen displaying the tracks inside a specific playlist, with full CRUD
/// operations (rename, delete, add tracks, remove individual tracks, play/shuffle).
class PlaylistDetailView extends ConsumerStatefulWidget {
  final String playlistName;

  const PlaylistDetailView({
    super.key,
    required this.playlistName,
  });

  @override
  ConsumerState<PlaylistDetailView> createState() => _PlaylistDetailViewState();
}

class _PlaylistDetailViewState extends ConsumerState<PlaylistDetailView> {
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _currentName = widget.playlistName;
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: isError ? AppColors.error : AppColors.accent,
                size: 20.0,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  message,
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

  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _currentName);

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

    if (newName != null && newName.isNotEmpty && newName != _currentName) {
      final success = await ref
          .read(playlistsProvider.notifier)
          .renamePlaylist(_currentName, newName);

      if (success) {
        setState(() {
          _currentName = newName;
        });
        _showFeedback('Renamed to "$newName"');
      } else {
        _showFeedback('Playlist "$newName" already exists', isError: true);
      }
    }
  }

  Future<void> _showDeleteConfirmDialog() async {
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
          'Are you sure you want to delete "$_currentName"? The audio files will remain on your device.',
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
      await ref.read(playlistsProvider.notifier).deletePlaylist(_currentName);
      if (mounted) {
        Navigator.pop(context);
        _showFeedback('Deleted playlist "$_currentName"');
      }
    }
  }

  Future<void> _removeSong(Song song) async {
    final success = await ref
        .read(playlistsProvider.notifier)
        .removeSongFromPlaylist(_currentName, song.id);

    if (success) {
      _showFeedback('Removed "${song.title}" from playlist');
    }
  }

  void _onSongTap(Song song, List<Song> playlistSongs) {
    final playerState = ref.read(playerViewModelProvider);
    if (playerState.currentSong?.id == song.id) {
      return;
    }
    ref.read(playerViewModelProvider.notifier).playSong(song, playlistSongs);
  }

  void _onPlayNext(Song song) {
    ref.read(playerViewModelProvider.notifier).insertNext(song);
    _showFeedback('Playing next: ${song.title}');
  }

  Future<void> _onDeleteSong(Song song) async {
    final libraryViewModel = ref.read(libraryViewModelProvider.notifier);
    final deleted = await libraryViewModel.deleteSong(song);
    if (deleted) {
      ref.read(playerViewModelProvider.notifier).removeSongFromPlayback(song.id);
      await ref.read(playlistsProvider.notifier).removeSongFromPlaylist(_currentName, song.id);
      _showFeedback('Deleted "${song.title}"');
    } else {
      _showFeedback('Could not delete "${song.title}"', isError: true);
    }
  }

  String _formatTotalDuration(List<Song> songs) {
    final totalMs = songs.fold<int>(0, (sum, s) => sum + s.durationMs);
    final totalSeconds = (totalMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remMinutes = minutes % 60;
      return '${hours}h ${remMinutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final songIds = playlists[_currentName] ?? <int>[];

    final libraryState = ref.watch(libraryViewModelProvider);
    final allSongs = libraryState is LibraryLoaded ? libraryState.songs : <Song>[];
    final playlistSongs = allSongs.where((s) => songIds.contains(s.id)).toList();

    final playerState = ref.watch(playerViewModelProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF131A2D),
            AppColors.background,
          ],
          stops: [0.0, 0.35],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _currentName,
            style: AppTextStyles.screenTitle.copyWith(fontSize: 18.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.playlist_add_rounded,
                color: AppColors.accent,
                size: 26.0,
              ),
              tooltip: 'Add Tracks',
              onPressed: () => PlaylistAddSongsSheet.show(
                context: context,
                playlistName: _currentName,
                currentSongIds: songIds,
                allSongs: allSongs,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textPrimary,
              ),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: AppColors.outline),
              ),
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog();
                } else if (value == 'add') {
                  PlaylistAddSongsSheet.show(
                    context: context,
                    playlistName: _currentName,
                    currentSongIds: songIds,
                    allSongs: allSongs,
                  );
                } else if (value == 'delete') {
                  _showDeleteConfirmDialog();
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.edit_rounded, color: AppColors.accent, size: 20.0),
                      SizedBox(width: AppDimensions.space12),
                      Text('Rename Playlist', style: AppTextStyles.body),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'add',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.add_rounded, color: AppColors.accent, size: 20.0),
                      SizedBox(width: AppDimensions.space12),
                      Text('Add Tracks', style: AppTextStyles.body),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1.0),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20.0),
                      SizedBox(width: AppDimensions.space12),
                      Text('Delete Playlist', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(
                  top: AppDimensions.space8,
                  bottom: AppDimensions.space16,
                ),
                children: <Widget>[
                  // Header Hero Box
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 64.0,
                            height: 64.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF222B48),
                                  Color(0xFF131A2D),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.queue_music_rounded,
                                color: AppColors.accent,
                                size: 32.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _currentName,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  '${playlistSongs.length} tracks • ${_formatTotalDuration(playlistSongs)}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space16),

                  // Action Buttons Row (Play All & Shuffle box buttons)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                    ),
                    child: Row(
                      children: <Widget>[
                        // Left Button: Play All
                        Expanded(
                          child: OutlinedButton(
                            onPressed: playlistSongs.isEmpty
                                ? null
                                : () {
                                    ref
                                        .read(playerViewModelProvider.notifier)
                                        .playSong(playlistSongs.first, playlistSongs);
                                  },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: playlistSongs.isEmpty
                                  ? AppColors.surface.withValues(alpha: 0.5)
                                  : AppColors.surface,
                              foregroundColor: playlistSongs.isEmpty
                                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                                  : AppColors.accent,
                              side: BorderSide(
                                color: playlistSongs.isEmpty
                                    ? AppColors.outline
                                    : AppColors.accent.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              minimumSize: const Size.fromHeight(38.0),
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(Icons.play_arrow_rounded, size: 20.0),
                                SizedBox(width: 6.0),
                                Text(
                                  'Play All',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        // Right Button: Shuffle
                        Expanded(
                          child: OutlinedButton(
                            onPressed: playlistSongs.isEmpty
                                ? null
                                : () {
                                    final shuffled = List<Song>.from(playlistSongs)..shuffle();
                                    ref
                                        .read(playerViewModelProvider.notifier)
                                        .playSong(shuffled.first, shuffled);
                                  },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: playlistSongs.isEmpty
                                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                                  : AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              minimumSize: const Size.fromHeight(38.0),
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(Icons.shuffle_rounded, size: 18.0),
                                SizedBox(width: 6.0),
                                Text(
                                  'Shuffle',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space16),

                  // Tracks Section Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Text(
                            '${playlistSongs.length} Tracks',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        const Expanded(
                          child: Divider(color: AppColors.outline, height: 1.0),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space8),

                  // Track List or Empty State
                  if (playlistSongs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(top: AppDimensions.space24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space24,
                          vertical: AppDimensions.space32,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 56.0,
                              height: 56.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.background,
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.queue_music_rounded,
                                  color: AppColors.accent,
                                  size: 28.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            const Text(
                              'No songs in this playlist yet',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space6),
                            const Text(
                              'Tap below to add songs from your library',
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimensions.space24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.onAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.space24,
                                  vertical: AppDimensions.space12,
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 20.0),
                              label: const Text(
                                'Add Songs',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () => PlaylistAddSongsSheet.show(
                                context: context,
                                playlistName: _currentName,
                                currentSongIds: songIds,
                                allSongs: allSongs,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final song in playlistSongs)
                      SongListTile(
                        key: ValueKey<int>(song.id),
                        song: song,
                        isPlaying: playerState.currentSong?.id == song.id &&
                            playerState.isPlaying,
                        onTap: () => _onSongTap(song, playlistSongs),
                        onMoreTap: () => SongOptionsModal.show(
                          context: context,
                          song: song,
                          onPlayNext: () => _onPlayNext(song),
                          onRemoveFromPlaylist: () => _removeSong(song),
                          onDeleteTap: () => _onDeleteSong(song),
                        ),
                      ),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }
}
