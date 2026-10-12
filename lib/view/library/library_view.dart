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
import '../player/widgets/mini_player.dart';
import 'widgets/library_action_bar.dart';
import 'widgets/library_header.dart';
import 'widgets/library_states.dart';
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: LibraryHeader(
          onSettingsTap: () => context.push(RouteNames.settingsPath),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: _buildBody(context, ref, state, viewModel),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    LibraryViewModel viewModel,
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
      LibraryLoaded() => _buildLoadedList(context, ref, viewModel),
    };
  }

  Widget _buildLoadedList(
    BuildContext context,
    WidgetRef ref,
    LibraryViewModel viewModel,
  ) {
    final filteredSongs = ref.watch(filteredSongsProvider);
    final activeQuery = ref.watch(libraryQueryProvider).trim();
    final playerState = ref.watch(playerViewModelProvider);

    // If a search query is active and yields no results, show search empty state
    if (activeQuery.isNotEmpty && filteredSongs.isEmpty) {
      return NoSearchResultsView(query: activeQuery);
    }

    return Column(
      children: <Widget>[
        // Quick Action Bar with Track Count, Sort, and Shuffle Pill
        LibraryActionBar(
          songCount: filteredSongs.length,
          onShuffleTap: () => _onShuffleTap(context, ref, filteredSongs),
          onSortTap: () => SongSortModal.show(context),
        ),

        // Scrollable song list with interactive scrollbar
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: viewModel.rescan,
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

                    return SongListTile(
                      key: ValueKey<int>(song.id),
                      song: song,
                      isPlaying: isCurrentSong && playerState.isPlaying,
                      onTap: () => _onSongTap(context, ref, song, filteredSongs),
                      onMoreTap: () => SongOptionsModal.show(
                        context: context,
                        song: song,
                        onPlayNext: () => _onPlayNext(context, ref, song),
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
    );
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
    ref.read(playerViewModelProvider.notifier).playSong(song, currentQueue);
  }

  void _onPlayNext(BuildContext context, WidgetRef ref, Song song) {
    ref.read(playerViewModelProvider.notifier).insertNext(song);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
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
          duration: const Duration(seconds: 2),
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
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
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
