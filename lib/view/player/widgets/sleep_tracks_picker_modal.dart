import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../model/song.dart';
import '../../../view_model/library/library_state.dart';
import '../../../view_model/library/library_view_model.dart';
import '../../../view_model/player/player_view_model.dart';
import '../../library/widgets/song_artwork.dart';

/// Modal bottom sheet allowing the user to select specific tracks for a track-based sleep timer.
///
/// Features:
/// - Tabs to pick from the current upcoming playback queue or the entire music library.
/// - Live instant search filtering.
/// - Multi-selection with clear counters and visual check states.
/// - Smooth Midnight Blue aesthetic conforming to Dozetone's design system.
class SleepTracksPickerModal extends ConsumerStatefulWidget {
  final List<Song> initialSelected;

  const SleepTracksPickerModal({
    super.key,
    this.initialSelected = const <Song>[],
  });

  /// Displays the SleepTracksPickerModal bottom sheet and returns the selected songs.
  static Future<List<Song>?> show({
    required BuildContext context,
    List<Song> initialSelected = const <Song>[],
  }) {
    return showModalBottomSheet<List<Song>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SleepTracksPickerModal(
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  ConsumerState<SleepTracksPickerModal> createState() =>
      _SleepTracksPickerModalState();
}

class _SleepTracksPickerModalState
    extends ConsumerState<SleepTracksPickerModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<Song> _selectedSongs = <Song>[];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedSongs.addAll(widget.initialSelected);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSongSelection(Song song) {
    setState(() {
      final index = _selectedSongs.indexWhere((s) => s.id == song.id);
      if (index >= 0) {
        _selectedSongs.removeAt(index);
      } else {
        _selectedSongs.add(song);
      }
    });
  }

  List<Song> _filterSongs(List<Song> songs) {
    if (_searchQuery.trim().isEmpty) return songs;
    final query = _searchQuery.toLowerCase();
    return songs.where((s) {
      final titleMatch = s.title.toLowerCase().contains(query);
      final artistMatch = s.artist.toLowerCase().contains(query);
      final albumMatch = (s.album ?? '').toLowerCase().contains(query);
      return titleMatch || artistMatch || albumMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final playerState = ref.watch(playerViewModelProvider);
    final libraryState = ref.watch(libraryViewModelProvider);

    // Queue tracks: upcoming tracks from current track onwards
    final queueTracks = <Song>[];
    if (playerState.queue.isNotEmpty) {
      final startIndex = playerState.currentIndex >= 0
          ? playerState.currentIndex
          : 0;
      queueTracks.addAll(playerState.queue.skip(startIndex));
    }

    final allLibrarySongs =
        libraryState is LibraryLoaded ? libraryState.songs : <Song>[];

    final filteredQueue = _filterSongs(queueTracks);
    final filteredLibrary = _filterSongs(allLibrarySongs);

    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusBottomSheet,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // Drag Handle
            const SizedBox(height: AppDimensions.space12),
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Header Row: Title & Selected Count
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: AppColors.accent,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.selectSleepTracks,
                          style: AppTextStyles.screenTitle.copyWith(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.musicWillTurnOffTracksFinish,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedSongs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: AppDimensions.borderRadiusPill,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        l10n.selectedCount(_selectedSongs.length),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
              ),
              child: Container(
                height: 42.0,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    hintText: l10n.searchSongsOrArtists,
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 13.0,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 20.0,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16.0,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Tab Bar: Up Next vs Library
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
              ),
              child: Container(
                height: 38.0,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  unselectedLabelStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.5,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: <Widget>[
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.playlist_play_rounded, size: 16.0),
                          const SizedBox(width: AppDimensions.space6),
                          Text(l10n.upcomingQueueCount(queueTracks.length)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.library_music_rounded, size: 16.0),
                          const SizedBox(width: AppDimensions.space6),
                          Text(l10n.allSongsCount(allLibrarySongs.length)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Tab Views: Song Lists
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildSongListView(
                    filteredQueue,
                    emptyMessage: queueTracks.isEmpty
                        ? l10n.noUpcomingSongsInQueue
                        : l10n.noMatchingSongsInQueue,
                  ),
                  _buildSongListView(
                    filteredLibrary,
                    emptyMessage: allLibrarySongs.isEmpty
                        ? l10n.noSongsFoundInLibrary
                        : l10n.noMatchingSongsInLibrary,
                  ),
                ],
              ),
            ),

            // Bottom Sticky Bar: Clear & Confirm
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  if (_selectedSongs.isNotEmpty) ...<Widget>[
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedSongs.clear());
                      },
                      child: Text(
                        l10n.clearQueue,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedSongs.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop(_selectedSongs);
                            },
                      icon: const Icon(Icons.check_rounded, size: 18.0),
                      label: Text(
                        _selectedSongs.isEmpty
                            ? l10n.selectSongsAction
                            : l10n.setTimerTracksCount(_selectedSongs.length),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        disabledBackgroundColor:
                            AppColors.surface.withValues(alpha: 0.5),
                        disabledForegroundColor:
                            AppColors.textSecondary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.space12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongListView(List<Song> songs, {required String emptyMessage}) {
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.music_off_rounded,
                size: 40.0,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space4,
      ),
      itemBuilder: (context, index) {
        final song = songs[index];
        final isSelected = _selectedSongs.any((s) => s.id == song.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.space6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleSongSelection(song),
              borderRadius: BorderRadius.circular(12.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space12,
                  vertical: AppDimensions.space8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    // Checkbox indicator
                    Container(
                      width: 22.0,
                      height: 22.0,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary.withValues(alpha: 0.6),
                          width: 1.8,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15.0,
                              color: AppColors.onAccent,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppDimensions.space12),

                    // Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: SizedBox(
                        width: 44.0,
                        height: 44.0,
                        child: SongArtwork(
                          songId: song.id,
                          albumId: song.albumId,
                          dataUri: song.dataUri,
                          size: 44.0,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),

                    // Title & Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: isSelected
                                  ? Color.lerp(
                                      AppColors.accent,
                                      AppColors.white,
                                      0.25,
                                    )
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Duration
                    Text(
                      song.formattedDuration,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
