import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../model/song.dart';
import '../../../view_model/playlist/favorites_provider.dart';

/// Modal bottom sheet for searching and batch-adding library songs to a playlist.
class PlaylistAddSongsSheet extends ConsumerStatefulWidget {
  final String playlistName;
  final List<int> currentSongIds;
  final List<Song> allSongs;

  const PlaylistAddSongsSheet({
    super.key,
    required this.playlistName,
    required this.currentSongIds,
    required this.allSongs,
  });

  /// Displays the modal sheet.
  static Future<void> show({
    required BuildContext context,
    required String playlistName,
    required List<int> currentSongIds,
    required List<Song> allSongs,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaylistAddSongsSheet(
        playlistName: playlistName,
        currentSongIds: currentSongIds,
        allSongs: allSongs,
      ),
    );
  }

  @override
  ConsumerState<PlaylistAddSongsSheet> createState() =>
      _PlaylistAddSongsSheetState();
}

class _PlaylistAddSongsSheetState extends ConsumerState<PlaylistAddSongsSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedSongIds = <int>{};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> get _filteredSongs {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.allSongs;
    }
    return widget.allSongs.where((song) {
      final title = song.title.toLowerCase();
      final artist = song.artist.toLowerCase();
      return title.contains(query) || artist.contains(query);
    }).toList();
  }

  Future<void> _onAddSelected() async {
    if (_selectedSongIds.isEmpty) return;

    final addedCount = await ref
        .read(playlistsProvider.notifier)
        .addSongsToPlaylist(widget.playlistName, _selectedSongIds.toList());

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20.0,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  'Added $addedCount track${addedCount == 1 ? '' : 's'} to "${widget.playlistName}"',
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

  @override
  Widget build(BuildContext context) {
    final availableSongs = _filteredSongs;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusBottomSheet,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.barrier,
            blurRadius: 24.0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppDimensions.space12),
            // Drag handle pill
            Center(
              child: Container(
                width: 38.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Sheet title and close icon
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Add Tracks',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Select songs for "${widget.playlistName}"',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space12),

            // Search input field
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search songs by title or artist...',
                  hintStyle: AppTextStyles.bodySecondary,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20.0,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: AppColors.textSecondary,
                            size: 18.0,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: AppDimensions.space12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space12),
            const Divider(color: AppColors.outline, height: 1.0),

            // Song list with check selections
            Expanded(
              child: availableSongs.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No library songs available'
                            : 'No songs matching "$_searchQuery"',
                        style: AppTextStyles.bodySecondary,
                      ),
                    )
                  : ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: availableSongs.length,
                      itemExtent: 64.0,
                      itemBuilder: (context, index) {
                        final song = availableSongs[index];
                        final alreadyInPlaylist =
                            widget.currentSongIds.contains(song.id);
                        final isSelected =
                            _selectedSongIds.contains(song.id);

                        return InkWell(
                          onTap: alreadyInPlaylist
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedSongIds.remove(song.id);
                                    } else {
                                      _selectedSongIds.add(song.id);
                                    }
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space16,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.softWhite(0.08),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                // Selection indicator / Checkbox
                                Container(
                                  width: 24.0,
                                  height: 24.0,
                                  decoration: BoxDecoration(
                                    color: alreadyInPlaylist
                                        ? AppColors.surface
                                        : isSelected
                                            ? AppColors.accent
                                            : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(6.0),
                                    border: Border.all(
                                      color: alreadyInPlaylist
                                          ? AppColors.outline
                                          : isSelected
                                              ? AppColors.accent
                                              : AppColors.textSecondary,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      alreadyInPlaylist
                                          ? Icons.check_rounded
                                          : isSelected
                                              ? Icons.check_rounded
                                              : null,
                                      size: 16.0,
                                      color: alreadyInPlaylist
                                          ? AppColors.textSecondary
                                          : AppColors.onAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.space16),

                                // Song details
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        song.title,
                                        style: TextStyle(
                                          fontFamily:
                                              AppTextStyles.fontFamily,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: alreadyInPlaylist
                                              ? AppColors.textSecondary
                                              : AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        alreadyInPlaylist
                                            ? '${song.artist} • Already added'
                                            : '${song.artist} • ${song.formattedDuration}',
                                        style:
                                            AppTextStyles.caption.copyWith(
                                          color: alreadyInPlaylist
                                              ? AppColors.textSecondary
                                                  .withValues(alpha: 0.7)
                                              : AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Add Action Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.outline, width: 1.0),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSongIds.isEmpty
                        ? AppColors.surface
                        : AppColors.accent,
                    foregroundColor: _selectedSongIds.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.onAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed:
                      _selectedSongIds.isEmpty ? null : _onAddSelected,
                  child: Text(
                    _selectedSongIds.isEmpty
                        ? 'Select Tracks to Add'
                        : 'Add ${_selectedSongIds.length} Track${_selectedSongIds.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
