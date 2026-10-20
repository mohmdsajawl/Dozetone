import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../model/song.dart';
import '../../../view_model/playlist/favorites_provider.dart';

/// Modal bottom sheet allowing users to add a track to Favorites or Playlists.
class AddToPlaylistModal extends ConsumerStatefulWidget {
  final Song song;
  final bool showFavorites;

  const AddToPlaylistModal({
    super.key,
    required this.song,
    this.showFavorites = true,
  });

  /// Displays the modal bottom sheet for [song].
  static Future<void> show({
    required BuildContext context,
    required Song song,
    bool showFavorites = true,
    @Deprecated('Queue options are now directly in SongOptionsModal')
    bool showQueueOptions = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddToPlaylistModal(
        song: song,
        showFavorites: showFavorites,
      ),
    );
  }

  @override
  ConsumerState<AddToPlaylistModal> createState() => _AddToPlaylistModalState();
}

class _AddToPlaylistModalState extends ConsumerState<AddToPlaylistModal> {
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
    final nowFav = await ref
        .read(favoritesProvider.notifier)
        .toggleFavorite(widget.song.id);

    if (mounted) {
      Navigator.pop(context);
      _showFeedback(
        nowFav ? 'Added to Favorites' : 'Removed from Favorites',
        nowFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      );
    }
  }

  Future<void> _onAddToPlaylist(String playlistName) async {
    final added = await ref
        .read(playlistsProvider.notifier)
        .addSongToPlaylist(playlistName, widget.song.id);
    if (!mounted) return;
    Navigator.pop(context);
    _showFeedback(
      added ? 'Added to $playlistName' : 'Already in $playlistName',
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
      await ref
          .read(playlistsProvider.notifier)
          .addSongToPlaylist(name, widget.song.id);
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

    final maxHeight = MediaQuery.of(context).size.height * 0.80;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.borderRadiusBottomSheet,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.barrier,
              blurRadius: 28.0,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Pinned Top Header (Drag handle, Title, and Divider)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space16,
                  AppDimensions.space12,
                  AppDimensions.space16,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                              Text(
                                widget.showFavorites ? 'Add to...' : 'Add to Playlist',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),

              // Scrollable Body (Favorites + Playlists List + Create button)
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space16,
                    AppDimensions.space12,
                    AppDimensions.space16,
                    AppDimensions.space24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1. Favorites row (only displayed when showFavorites is true, e.g. from MiniPlayer)
                      if (widget.showFavorites) ...<Widget>[
                        _buildOptionTile(
                          icon: isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor: isFavorite ? AppColors.favorite : AppColors.accent,
                          title: 'Favorites',
                          subtitle: isFavorite
                              ? 'Already in Favorites (tap to remove)'
                              : 'Save to favorite tracks',
                          trailing: Icon(
                            isFavorite ? Icons.check_circle_rounded : Icons.add_rounded,
                            color: isFavorite ? AppColors.favorite : AppColors.accent,
                            size: 24.0,
                          ),
                          onTap: _toggleFavorite,
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // 2. Playlists Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.playlist_add_rounded,
                                color: AppColors.accent,
                                size: 20.0,
                              ),
                              const SizedBox(width: AppDimensions.space8),
                              Text(
                                'Playlists'.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${playlists.length} available',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space8),

                      // Playlists items
                      if (playlists.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space16,
                            vertical: AppDimensions.space16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.5),
                            borderRadius: AppDimensions.borderRadiusCard,
                            border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No playlists yet. Create one below!',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...playlists.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                            child: _buildSubOption(
                              icon: Icons.album_rounded,
                              title: entry.key,
                              subtitle: '${entry.value.length} tracks',
                              onTap: () => _onAddToPlaylist(entry.key),
                            ),
                          );
                        }),

                      const SizedBox(height: AppDimensions.space4),

                      // Create New Playlist button
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
                ),
              ),
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

  Widget _buildSubOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.textSecondary, size: 18.0),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}
