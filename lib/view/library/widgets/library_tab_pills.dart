import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../view_model/playlist/favorites_provider.dart';

/// Top non-scrollable navigation bar for switching between All Songs, Favorites, and Playlists.
///
/// Features increased height for prominence, evenly distributed tabs,
/// and an active accent underline precisely matching the width of the tab content.
class LibraryTabPills extends ConsumerWidget {
  const LibraryTabPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(libraryTabProvider);
    final favorites = ref.watch(favoritesProvider);
    final playlists = ref.watch(playlistsProvider);

    return Container(
      height: 54.0,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          // 1. All Songs Tab
          Expanded(
            child: _buildNavTab(
              context: context,
              label: 'All Songs',
              icon: Icons.music_note_rounded,
              isSelected: activeTab == LibraryTab.all,
              onTap: () =>
                  ref.read(libraryTabProvider.notifier).state = LibraryTab.all,
            ),
          ),

          // 2. Favorites Tab
          Expanded(
            child: _buildNavTab(
              context: context,
              label: 'Favorites',
              icon: Icons.favorite_rounded,
              badgeCount: favorites.isNotEmpty ? favorites.length : null,
              isSelected: activeTab == LibraryTab.favorites,
              onTap: () => ref.read(libraryTabProvider.notifier).state =
                  LibraryTab.favorites,
            ),
          ),

          // 3. Playlists Tab
          Expanded(
            child: _buildNavTab(
              context: context,
              label: 'Playlists',
              icon: Icons.playlist_play_rounded,
              badgeCount: playlists.isNotEmpty ? playlists.length : null,
              isSelected: activeTab == LibraryTab.playlists,
              onTap: () => ref.read(libraryTabProvider.notifier).state =
                  LibraryTab.playlists,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    int? badgeCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      icon,
                      size: 16.0,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.space6),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (badgeCount != null) ...<Widget>[
                      const SizedBox(width: AppDimensions.space6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.5,
                          vertical: 1.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.18)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(6.0),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color:
                                      AppColors.outline.withValues(alpha: 0.6),
                                ),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10.0,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),

                // Active underline precisely matching the width of the content above
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: isSelected
                        ? <BoxShadow>[
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 4.0,
                              offset: const Offset(0, -1),
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
