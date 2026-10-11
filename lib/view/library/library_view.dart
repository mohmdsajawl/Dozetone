import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../model/song.dart';
import '../../view_model/library/filtered_songs_provider.dart';
import '../../view_model/library/library_search_query_provider.dart';
import '../../view_model/library/library_state.dart';
import '../../view_model/library/library_view_model.dart';
import 'widgets/library_header.dart';
import 'widgets/library_states.dart';
import 'widgets/song_list_tile.dart';

/// Main Song Library screen of Dozetone.
///
/// Features dynamic header search, pull to refresh, smooth scrolling
/// for thousands of songs, and distinct views for all five UI states.
class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final viewModel = ref.read(libraryViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: LibraryHeader(
        onSettingsTap: () => context.push(RouteNames.settingsPath),
      ),
      body: _buildBody(context, ref, state, viewModel),
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

    // If a search query is active and yields no results, show search empty state
    if (activeQuery.isNotEmpty && filteredSongs.isEmpty) {
      return NoSearchResultsView(query: activeQuery);
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: viewModel.rescan,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          top: AppDimensions.space8,
          bottom: AppDimensions.space32,
        ),
        itemCount: filteredSongs.length,
        itemExtent: AppDimensions.listRowHeight,
        itemBuilder: (context, index) {
          final song = filteredSongs[index];

          return SongListTile(
            key: ValueKey<int>(song.id),
            song: song,
            isPlaying: false,
            onTap: () => _onSongTap(context, ref, song, filteredSongs),
          );
        },
      ),
    );
  }

  void _onSongTap(
    BuildContext context,
    WidgetRef ref,
    Song song,
    List<Song> currentQueue,
  ) {
    // In Phase 2, this triggers playback through the DozetoneAudioHandler
    debugPrint('Song tapped: ${song.title} by ${song.artist}');
  }
}
