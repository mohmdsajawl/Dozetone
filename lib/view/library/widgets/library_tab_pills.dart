import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../view_model/playlist/favorites_provider.dart';

/// Top horizontal tab pills for switching between All Songs, Favorites, and Playlists.
class LibraryTabPills extends ConsumerWidget {
  const LibraryTabPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(libraryTabProvider);
    final favorites = ref.watch(favoritesProvider);
    final playlists = ref.watch(playlistsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space8,
      ),
      child: Row(
        children: <Widget>[
          _buildPill(
            context: context,
            label: 'All Songs',
            icon: Icons.music_note_rounded,
            isSelected: activeTab == LibraryTab.all,
            onTap: () => ref.read(libraryTabProvider.notifier).state = LibraryTab.all,
          ),
          const SizedBox(width: AppDimensions.space8),
          _buildPill(
            context: context,
            label: 'Favorites',
            icon: Icons.favorite_rounded,
            badgeCount: favorites.isNotEmpty ? favorites.length : null,
            isSelected: activeTab == LibraryTab.favorites,
            onTap: () => ref.read(libraryTabProvider.notifier).state = LibraryTab.favorites,
          ),
          const SizedBox(width: AppDimensions.space8),
          _buildPill(
            context: context,
            label: 'Playlists',
            icon: Icons.playlist_play_rounded,
            badgeCount: playlists.isNotEmpty ? playlists.length : null,
            isSelected: activeTab == LibraryTab.playlists,
            onTap: () => ref.read(libraryTabProvider.notifier).state = LibraryTab.playlists,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required BuildContext context,
    required String label,
    required IconData icon,
    int? badgeCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 34.0,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.outline,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 16.0,
              color: isSelected ? AppColors.onAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimensions.space6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.onAccent : AppColors.textSecondary,
              ),
            ),
            if (badgeCount != null) ...<Widget>[
              const SizedBox(width: AppDimensions.space6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.onAccent.withValues(alpha: 0.2)
                      : AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.onAccent : AppColors.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
