import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Docked bottom action bar rendered during multi-select mode in place of MiniPlayer.
///
/// Exposes batch actions: Add to Queue, Add to Playlist, Set Sleep Timer,
/// Add to Favorites, and Delete.
class BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onQueueTap;
  final VoidCallback onPlaylistTap;
  final VoidCallback onSleepTimerTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onDeleteTap;

  const BatchActionBar({
    super.key,
    required this.selectedCount,
    required this.onQueueTap,
    required this.onPlaylistTap,
    required this.onSleepTimerTap,
    required this.onFavoriteTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.space8,
        right: AppDimensions.space8,
        top: AppDimensions.space8,
        bottom: bottomPadding > 0 ? bottomPadding : AppDimensions.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.outline),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.35),
            offset: const Offset(0, -3),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildActionButton(
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: onQueueTap,
          ),
          _buildActionButton(
            icon: Icons.playlist_add_rounded,
            label: 'Playlist',
            onTap: onPlaylistTap,
          ),
          _buildActionButton(
            icon: Icons.bedtime_rounded,
            label: 'Timer',
            iconColor: AppColors.accent,
            onTap: onSleepTimerTap,
          ),
          _buildActionButton(
            icon: Icons.favorite_rounded,
            label: 'Favorite',
            iconColor: AppColors.favorite,
            onTap: onFavoriteTap,
          ),
          _buildActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            iconColor: AppColors.error,
            onTap: onDeleteTap,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 22.0,
              color: iconColor ?? AppColors.textPrimary,
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.0,
                color: iconColor ?? AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
