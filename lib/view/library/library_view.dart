import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../model/song.dart';
import '../../view_model/library/filtered_songs_provider.dart';
import '../../view_model/library/library_search_query_provider.dart';
import '../../view_model/library/library_state.dart';
import '../../view_model/library/library_view_model.dart';
import '../../view_model/player/player_view_model.dart';
import '../../view_model/playlist/favorites_provider.dart';
import '../player/widgets/mini_player.dart';
import 'package:flutter/services.dart';
import '../../view_model/library/multi_select_provider.dart';
import '../../view_model/sleep_timer/sleep_timer_view_model.dart';
import 'widgets/batch_action_bar.dart';
import 'widgets/batch_add_to_playlist_modal.dart';
import 'widgets/library_action_bar.dart';
import 'widgets/library_header.dart';
import 'widgets/library_states.dart';
import 'widgets/library_tab_pills.dart';
import 'widgets/multi_select_action_bar.dart';
import 'widgets/playlists_tab_view.dart';
import 'widgets/song_artwork.dart';
import 'widgets/song_list_tile.dart';
import 'widgets/song_options_modal.dart';
import 'widgets/song_sort_modal.dart';

/// Main Song Library screen of Dozetone.
///
/// Features dynamic header search, pull to refresh, smooth scrolling
/// for thousands of songs, quick action bar (shuffle and track count),
/// dynamic gradient fallback covers, and modal track options.
class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final viewModel = ref.read(libraryViewModelProvider.notifier);
    final filteredSongs = ref.watch(filteredSongsProvider);
    final selectedSongIds = ref.watch(multiSelectProvider);
    final isSelectionMode = selectedSongIds.isNotEmpty;

    // If already loaded when build executes, ensure session is restored
    if (state is LibraryLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(playerViewModelProvider.notifier).restoreSavedSession(state.songs);
      });
    }

    ref.listen<LibraryState>(libraryViewModelProvider, (previous, next) {
      if (next is LibraryLoaded) {
        ref.read(playerViewModelProvider.notifier).restoreSavedSession(next.songs);
      }
    });


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
      child: PopScope(
        canPop: !isSelectionMode,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && isSelectionMode) {
            ref.read(multiSelectProvider.notifier).clear();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: isSelectionMode
              ? MultiSelectActionBar(
                  selectedCount: selectedSongIds.length,
                  totalCount: filteredSongs.length,
                  onCancel: () => ref.read(multiSelectProvider.notifier).clear(),
                  onSelectAllToggle: () {
                    final notifier = ref.read(multiSelectProvider.notifier);
                    if (selectedSongIds.length == filteredSongs.length) {
                      notifier.clear();
                    } else {
                      notifier.selectAll(filteredSongs.map((s) => s.id));
                    }
                  },
                )
              : LibraryHeader(
                  onSettingsTap: () => context.push(RouteNames.settingsPath),
                  onSortTap: () => SongSortModal.show(context),
                ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: _buildBody(
                  context,
                  ref,
                  state,
                  viewModel,
                  filteredSongs,
                  selectedSongIds,
                  isSelectionMode,
                ),
              ),
              if (isSelectionMode)
                BatchActionBar(
                  selectedCount: selectedSongIds.length,
                  onQueueTap: () => _handleBatchQueue(
                    context,
                    ref,
                    filteredSongs,
                    selectedSongIds,
                  ),
                  onPlaylistTap: () => _handleBatchPlaylist(
                    context,
                    ref,
                    selectedSongIds,
                  ),
                  onSleepTimerTap: () => _handleBatchSleepTimer(
                    context,
                    ref,
                    filteredSongs,
                    selectedSongIds,
                  ),
                  onFavoriteTap: () => _handleBatchFavorite(
                    context,
                    ref,
                    selectedSongIds,
                  ),
                  onDeleteTap: () => _handleBatchDelete(
                    context,
                    ref,
                    viewModel,
                    filteredSongs,
                    selectedSongIds,
                  ),
                )
              else
                const MiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    LibraryViewModel viewModel,
    List<Song> filteredSongs,
    Set<int> selectedSongIds,
    bool isSelectionMode,
  ) {
    return switch (state) {
      LibraryPermissionRequired(:final isPermanentlyDenied) =>
        PermissionRequiredView(
          isPermanentlyDenied: isPermanentlyDenied,
          onGrantTap: viewModel.requestPermission,
          onSettingsTap: viewModel.openSettings,
        ),
      LibraryScanning() => const ScanningSongsView(),
      LibraryEmpty() => const EmptyLibraryView(),
      LibraryError(:final message) => ErrorLibraryView(
          message: message,
          onRetry: viewModel.scanSongs,
        ),
      LibraryLoaded() => _buildLoadedList(
          context,
          ref,
          viewModel,
          filteredSongs,
          selectedSongIds,
          isSelectionMode,
        ),
    };
  }

  Widget _buildLoadedList(
    BuildContext context,
    WidgetRef ref,
    LibraryViewModel viewModel,
    List<Song> filteredSongs,
    Set<int> selectedSongIds,
    bool isSelectionMode,
  ) {
    final activeTab = ref.watch(libraryTabProvider);
    final activeQuery = ref.watch(libraryQueryProvider).trim();
    final playerState = ref.watch(playerViewModelProvider);

    // Sync playback queue dynamically whenever songs are sorted or filtered
    ref.listen<List<Song>>(filteredSongsProvider, (previous, next) {
      if (next.isNotEmpty) {
        ref.read(playerViewModelProvider.notifier).updatePlaybackQueue(next);
      }
    });

    return Column(
      children: <Widget>[
        // Top filter pills: All Songs, Favorites, Playlists (hidden during multi-select)
        if (!isSelectionMode) const LibraryTabPills(),

        if (activeTab == LibraryTab.playlists && !isSelectionMode)
          const Expanded(child: PlaylistsTabView())
        else if (activeQuery.isNotEmpty && filteredSongs.isEmpty)
          Expanded(child: NoSearchResultsView(query: activeQuery))
        else if (activeTab == LibraryTab.favorites && filteredSongs.isEmpty)
          const Expanded(child: NoFavoritesView())
        else ...<Widget>[
          // Hero Action Bar with Play All, Shuffle, and Track Count (hidden during multi-select)
          if (!isSelectionMode)
            LibraryActionBar(
              songCount: filteredSongs.length,
              onPlayAllTap: () => _onPlayAllTap(context, ref, filteredSongs),
              onShuffleTap: () => _onShuffleTap(context, ref, filteredSongs),
            ),

          // Scrollable song list with interactive scrollbar
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                SongArtworkCache.clear();
                await viewModel.rescan();
              },
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  physics: const ClampingScrollPhysics(),
                  overscroll: false,
                ),
                child: Scrollbar(
                  interactive: true,
                  thickness: 3.5,
                  radius: const Radius.circular(2.0),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      top: AppDimensions.space4,
                      bottom: AppDimensions.space16,
                    ),
                    itemCount: filteredSongs.length,
                    itemExtent: AppDimensions.listRowHeight,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      final isCurrentSong = playerState.currentSong?.id == song.id;
                      final isSelected = selectedSongIds.contains(song.id);

                      return SongListTile(
                        key: ValueKey<int>(song.id),
                        song: song,
                        isPlaying: isCurrentSong && playerState.isPlaying,
                        isSelectionMode: isSelectionMode,
                        isSelected: isSelected,
                        onTap: () {
                          if (isSelectionMode) {
                            HapticFeedback.selectionClick();
                            ref.read(multiSelectProvider.notifier).toggle(song.id);
                          } else {
                            _onSongTap(context, ref, song, filteredSongs);
                          }
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          ref.read(multiSelectProvider.notifier).toggle(song.id);
                        },
                        onMoreTap: isSelectionMode
                            ? null
                            : () => SongOptionsModal.show(
                                context: context,
                                song: song,
                                onPlayNext: () => _onPlayNext(context, ref, song),
                                onRemoveFromFavorites:
                                    activeTab == LibraryTab.favorites
                                        ? () => _onRemoveFromFavorites(
                                            context, ref, song)
                                        : null,
                                onDeleteTap: () =>
                                    _onDeleteSong(context, ref, viewModel, song),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _onPlayAllTap(
    BuildContext context,
    WidgetRef ref,
    List<Song> currentQueue,
  ) {
    if (currentQueue.isEmpty) return;
    ref.read(playerViewModelProvider.notifier).playSong(currentQueue.first, currentQueue);
  }

  void _onShuffleTap(
    BuildContext context,
    WidgetRef ref,
    List<Song> currentQueue,
  ) {
    if (currentQueue.isEmpty) return;
    final shuffled = List<Song>.from(currentQueue)..shuffle();
    ref.read(playerViewModelProvider.notifier).playSong(shuffled.first, shuffled);
  }

  void _onSongTap(
    BuildContext context,
    WidgetRef ref,
    Song song,
    List<Song> currentQueue,
  ) {
    final playerState = ref.read(playerViewModelProvider);
    // If the tapped song is already the current track, do nothing
    if (playerState.currentSong?.id == song.id) {
      return;
    }
    ref.read(playerViewModelProvider.notifier).playSong(song, currentQueue);
  }

  void _showFloatingSnackBar(
    BuildContext context,
    WidgetRef ref, {
    required Widget content,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final hasMiniPlayer = ref.read(playerViewModelProvider).currentSong != null;
    final isSelectionMode = ref.read(multiSelectProvider).isNotEmpty;
    final bottomMargin = hasMiniPlayer
        ? (AppDimensions.miniPlayerHeight + AppDimensions.space24) // 88.0 dp
        : (isSelectionMode ? 72.0 : AppDimensions.space16);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: AppDimensions.space16,
            right: AppDimensions.space16,
            bottom: bottomMargin,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusCard,
            side: BorderSide(color: AppColors.outline),
          ),
          backgroundColor: AppColors.surface,
          duration: duration,
          content: content,
          action: action,
        ),
      );
  }

  void _onPlayNext(BuildContext context, WidgetRef ref, Song song) {
    ref.read(playerViewModelProvider.notifier).insertNext(song);
    _showFloatingSnackBar(
      context,
      ref,
      duration: const Duration(seconds: 2),
      content: Row(
        children: <Widget>[
          const Icon(
            Icons.queue_music_rounded,
            color: AppColors.accent,
            size: 20.0,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              'Playing next: ${song.title}',
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
    );
  }

  Future<void> _onRemoveFromFavorites(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) async {
    await ref.read(favoritesProvider.notifier).toggleFavorite(song.id);
    if (!context.mounted) return;
    _showFloatingSnackBar(
      context,
      ref,
      duration: const Duration(seconds: 2),
      content: Row(
        children: <Widget>[
          const Icon(
            Icons.favorite_border_rounded,
            color: AppColors.accent,
            size: 20.0,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              'Removed "${song.title}" from Favorites',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDeleteSong(
    BuildContext context,
    WidgetRef ref,
    LibraryViewModel viewModel,
    Song song,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final deleted = await viewModel.deleteSong(song);

    if (deleted) {
      ref.read(playerViewModelProvider.notifier).removeSongFromPlayback(song.id);
    }

    if (!context.mounted) return;

    _showFloatingSnackBar(
      context,
      ref,
      duration: const Duration(seconds: 3),
      content: Row(
        children: <Widget>[
          Icon(
            deleted
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: deleted ? AppColors.accent : AppColors.error,
            size: 20.0,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              deleted
                  ? l10n.songDeleted(song.title)
                  : l10n.songDeleteFailed(song.title),
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
    );
  }

  void _handleBatchQueue(
    BuildContext context,
    WidgetRef ref,
    List<Song> allSongs,
    Set<int> selectedIds,
  ) {
    final selectedSongs =
        allSongs.where((s) => selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;

    ref.read(playerViewModelProvider.notifier).addSongsToQueue(selectedSongs);
    ref.read(multiSelectProvider.notifier).clear();

    _showFloatingSnackBar(
      context,
      ref,
      duration: const Duration(seconds: 2),
      content: Row(
        children: <Widget>[
          const Icon(
            Icons.queue_music_rounded,
            color: AppColors.accent,
            size: 20.0,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              'Added ${selectedSongs.length} ${selectedSongs.length == 1 ? "track" : "tracks"} to queue',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBatchPlaylist(
    BuildContext context,
    WidgetRef ref,
    Set<int> selectedIds,
  ) async {
    final playlistName = await BatchAddToPlaylistModal.show(
      context: context,
      songIds: selectedIds.toList(),
    );

    if (playlistName != null && context.mounted) {
      ref.read(multiSelectProvider.notifier).clear();
      _showFloatingSnackBar(
        context,
        ref,
        duration: const Duration(seconds: 2),
        content: Row(
          children: <Widget>[
            const Icon(
              Icons.playlist_add_check_rounded,
              color: AppColors.accent,
              size: 20.0,
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                'Added ${selectedIds.length} ${selectedIds.length == 1 ? "track" : "tracks"} to "$playlistName"',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleBatchSleepTimer(
    BuildContext context,
    WidgetRef ref,
    List<Song> allSongs,
    Set<int> selectedIds,
  ) async {
    final selectedSongs =
        allSongs.where((s) => selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;

    // Immediately clear multi-select mode so UI dismisses the selection mode right away
    ref.read(multiSelectProvider.notifier).clear();

    // Start sleep timer first so state is active immediately
    await ref.read(sleepTimerProvider.notifier).startTracksTimer(
          trackCount: selectedSongs.length,
          specificTracks: selectedSongs,
          choiceLabel: '${selectedSongs.length} tracks',
        );

    // Then start playing the selected tracks with the selected tracks as queue
    await ref
        .read(playerViewModelProvider.notifier)
        .playSong(selectedSongs.first, selectedSongs);

    if (context.mounted) {
      final label =
          '${selectedSongs.length} ${selectedSongs.length == 1 ? "track" : "tracks"}';
      _showFloatingSnackBar(
        context,
        ref,
        duration: const Duration(seconds: 2),
        content: Row(
          children: <Widget>[
            const Icon(
              Icons.bedtime_rounded,
              color: AppColors.accent,
              size: 20.0,
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                'Sleep timer set for $label',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleBatchFavorite(
    BuildContext context,
    WidgetRef ref,
    Set<int> selectedIds,
  ) async {
    await ref.read(favoritesProvider.notifier).addFavorites(selectedIds);
    ref.read(multiSelectProvider.notifier).clear();

    if (context.mounted) {
      _showFloatingSnackBar(
        context,
        ref,
        duration: const Duration(seconds: 2),
        content: Row(
          children: <Widget>[
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF5252),
              size: 20.0,
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                'Added ${selectedIds.length} ${selectedIds.length == 1 ? "track" : "tracks"} to Favorites',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleBatchDelete(
    BuildContext context,
    WidgetRef ref,
    LibraryViewModel viewModel,
    List<Song> allSongs,
    Set<int> selectedIds,
  ) async {
    final selectedSongs =
        allSongs.where((s) => selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;

    final count = selectedSongs.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.outline),
        ),
        title: Text(
          'Delete $count ${count == 1 ? "Track" : "Tracks"}?',
          style: AppTextStyles.screenTitle,
        ),
        content: Text(
          'Are you sure you want to permanently delete $count ${count == 1 ? "track" : "tracks"} from your device storage? This cannot be undone.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deletedCount = await viewModel.deleteSongs(selectedSongs);
      for (final song in selectedSongs) {
        ref.read(playerViewModelProvider.notifier).removeSongFromPlayback(song.id);
      }
      ref.read(multiSelectProvider.notifier).clear();

      if (context.mounted) {
        _showFloatingSnackBar(
          context,
          ref,
          duration: const Duration(seconds: 3),
          content: Row(
            children: <Widget>[
              Icon(
                deletedCount > 0
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: deletedCount > 0 ? AppColors.accent : AppColors.error,
                size: 20.0,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  'Permanently deleted $deletedCount ${deletedCount == 1 ? "track" : "tracks"}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}

