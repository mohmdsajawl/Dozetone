import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../model/song.dart';
import '../../../view_model/player/player_view_model.dart';
import '../../../view_model/playlist/favorites_provider.dart';

/// Modal bottom sheet allowing users to add a track to Favorites,
/// Queue (Play Next / End / New Queue), or Playlists & Albums.
class AddToPlaylistModal extends ConsumerStatefulWidget {
  final Song song;

  const AddToPlaylistModal({
    super.key,
    required this.song,
  });

  /// Displays the modal bottom sheet for [song].
  static Future<void> show({
    required BuildContext context,
    required Song song,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddToPlaylistModal(song: song),
    );
  }

  @override
  ConsumerState<AddToPlaylistModal> createState() => _AddToPlaylistModalState();
}

class _AddToPlaylistModalState extends ConsumerState<AddToPlaylistModal> {
  bool _isQueueExpanded = false;
  bool _isPlaylistsExpanded = false;

  void _showFeedback(String message, IconData icon) {
    if (!mounted) return;
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

  Future<void> _toggleFavorite() async {
    final nowFav = await ref.read(favoritesProvider.notifier).toggleFavorite(widget.song.id);

    if (mounted) {
      Navigator.pop(context);
      _showFeedback(
        nowFav
            ? 'Added to Favorites'
            : 'Removed from Favorites',
        nowFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      );
    }
  }

  void _onPlayNext() {
    ref.read(playerViewModelProvider.notifier).insertNext(widget.song);
    Navigator.pop(context);
    _showFeedback(
      'Playing next: ${widget.song.title}',
      Icons.playlist_play_rounded,
    );
  }

  void _onAddToQueue() {
    ref.read(playerViewModelProvider.notifier).addToQueue(widget.song);
    Navigator.pop(context);
    _showFeedback(
      'Added to queue: ${widget.song.title}',
      Icons.queue_music_rounded,
    );
  }

  Future<void> _onCreateNewQueue() async {
    ref.read(playerViewModelProvider.notifier).playSong(widget.song, <Song>[widget.song]);
    Navigator.pop(context);
    _showFeedback(
      'Started new queue with ${widget.song.title}',
      Icons.play_arrow_rounded,
    );
  }

  Future<void> _onAddToPlaylist(String playlistName) async {
    final added = await ref.read(playlistsProvider.notifier).addSongToPlaylist(playlistName, widget.song.id);
    if (!mounted) return;
    Navigator.pop(context);
    _showFeedback(
      added
          ? 'Added to $playlistName'
          : 'Already in $playlistName',
      Icons.playlist_add_check_rounded,
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusCard,
        ),
        title: const Text(
          'New Playlist',
          style: AppTextStyles.screenTitle,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Playlist name',
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
      await ref.read(playlistsProvider.notifier).createPlaylist(name);
      await ref.read(playlistsProvider.notifier).addSongToPlaylist(name, widget.song.id);
      if (!mounted) return;
      Navigator.pop(context);
      _showFeedback(
        'Created playlist "$name" and added track',
        Icons.check_circle_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final playlists = ref.watch(playlistsProvider);
    final isFavorite = favorites.contains(widget.song.id);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusBottomSheet,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black45,
            blurRadius: 24.0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Modal pill handle
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

              // Title and track subtitle
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.add_to_photos_rounded,
                    color: AppColors.accent,
                    size: 22.0,
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Add to...',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '${widget.song.title} • ${widget.song.artist}',
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
              const SizedBox(height: AppDimensions.space12),

              // 1. Favorites row
              _buildOptionTile(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: isFavorite ? Colors.redAccent : AppColors.accent,
                title: 'Favorites',
                subtitle: isFavorite
                    ? 'Already in Favorites (tap to remove)'
                    : 'Save to favorite tracks',
                trailing: Icon(
                  isFavorite ? Icons.check_circle_rounded : Icons.add_rounded,
                  color: isFavorite ? Colors.redAccent : AppColors.accent,
                  size: 24.0,
                ),
                onTap: _toggleFavorite,
              ),

              const SizedBox(height: AppDimensions.space8),

              // 2. Queue expandable accordion
              _buildExpandableTile(
                icon: Icons.queue_music_rounded,
                title: 'Queue',
                subtitle: 'Play next, add to end, or start new queue',
                isExpanded: _isQueueExpanded,
                onHeaderTap: () {
                  setState(() {
                    _isQueueExpanded = !_isQueueExpanded;
                  });
                },
                children: <Widget>[
                  _buildSubOption(
                    icon: Icons.playlist_play_rounded,
                    title: 'Play Next',
                    subtitle: 'Insert immediately after current track',
                    onTap: _onPlayNext,
                  ),
                  _buildSubOption(
                    icon: Icons.low_priority_rounded,
                    title: 'Add to End of Queue',
                    subtitle: 'Append to the bottom of the active queue',
                    onTap: _onAddToQueue,
                  ),
                  _buildSubOption(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'New Queue',
                    subtitle: 'Clear and start new queue with this song',
                    onTap: _onCreateNewQueue,
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space8),

              // 3. Playlists & Albums expandable accordion
              _buildExpandableTile(
                icon: Icons.playlist_add_rounded,
                title: 'Playlists & Albums',
                subtitle: '${playlists.length} playlists available',
                isExpanded: _isPlaylistsExpanded,
                onHeaderTap: () {
                  setState(() {
                    _isPlaylistsExpanded = !_isPlaylistsExpanded;
                  });
                },
                children: <Widget>[
                  for (final entry in playlists.entries)
                    _buildSubOption(
                      icon: Icons.album_rounded,
                      title: entry.key,
                      subtitle: '${entry.value.length} tracks',
                      onTap: () => _onAddToPlaylist(entry.key),
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    // + Create New Playlist button
                    InkWell(
                      onTap: _showCreatePlaylistDialog,
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.add_rounded,
                              color: AppColors.accent,
                              size: 20.0,
                            ),
                            SizedBox(width: AppDimensions.space8),
                            Text(
                              'Create New Playlist',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
              ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space12,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 22.0),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onHeaderTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space12,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Center(
                      child: Icon(icon, color: AppColors.accent, size: 22.0),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(subtitle, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 24.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space12,
                0,
                AppDimensions.space12,
                AppDimensions.space12,
              ),
              child: Column(
                children: <Widget>[
                  const Divider(color: AppColors.outline, height: 1.0),
                  const SizedBox(height: AppDimensions.space8),
                  ...children,
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildSubOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space8,
            vertical: AppDimensions.space8,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.textSecondary, size: 20.0),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(fontSize: 11.0),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.accent,
                    size: 18.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
