import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Quick Action Bar below the Library header.
///
/// Features consistent 34 dp height across all elements:
/// track count badge, sort action button, and vibrant cyan shuffle button.
class LibraryActionBar extends StatelessWidget {
  final int songCount;
  final VoidCallback onShuffleTap;
  final VoidCallback onSortTap;

  const LibraryActionBar({
    super.key,
    required this.songCount,
    required this.onShuffleTap,
    required this.onSortTap,
  });

  static const double _controlHeight = 34.0;
  static const BorderRadius _controlBorderRadius =
      BorderRadius.all(Radius.circular(10.0));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnabled = songCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space8,
      ),
      child: Row(
        children: <Widget>[
          // 1. Track count badge
          Container(
            height: _controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: _controlBorderRadius,
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.music_note_rounded,
                  size: 15.0,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppDimensions.space4),
                Text(
                  l10n.songsCount(songCount),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // 2. Sort button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSortTap,
              borderRadius: _controlBorderRadius,
              child: Container(
                height: _controlHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: _controlBorderRadius,
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.swap_vert_rounded,
                      size: 16.0,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Text(
                      l10n.sortBy,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space8),

          // 3. Shuffle pill button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? onShuffleTap : null,
              borderRadius: _controlBorderRadius,
              child: Container(
                height: _controlHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
                decoration: BoxDecoration(
                  color: isEnabled ? AppColors.accent : AppColors.surface,
                  borderRadius: _controlBorderRadius,
                  border: isEnabled ? null : Border.all(color: AppColors.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.shuffle_rounded,
                      size: 15.0,
                      color: isEnabled ? AppColors.background : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Text(
                      l10n.shuffle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isEnabled ? AppColors.background : AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
