import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Action bar below the Library navbar tabs.
///
/// Houses left-aligned Play All and right-aligned Shuffle box buttons,
/// followed by an anchored, highlighted track count section header for the list.
class LibraryActionBar extends StatelessWidget {
  final int songCount;
  final VoidCallback onPlayAllTap;
  final VoidCallback onShuffleTap;

  const LibraryActionBar({
    super.key,
    required this.songCount,
    required this.onPlayAllTap,
    required this.onShuffleTap,
  });

  static const double _buttonHeight = 36.0;
  static const BorderRadius _boxBorderRadius =
      BorderRadius.all(Radius.circular(10.0));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnabled = songCount > 0;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.space16,
        right: AppDimensions.space16,
        top: AppDimensions.space12,
        bottom: AppDimensions.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Actions Row: Left-aligned Play All and Right-aligned Shuffle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // 1. Left-aligned Play All Box Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? onPlayAllTap : null,
                  borderRadius: _boxBorderRadius,
                  child: Container(
                    height: _buttonHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: _boxBorderRadius,
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.8),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 20.0,
                          color: isEnabled
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.space6),
                        Text(
                          l10n.playAll,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Right-aligned Shuffle Box Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? onShuffleTap : null,
                  borderRadius: _boxBorderRadius,
                  child: Container(
                    height: _buttonHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                    ),
                    decoration: BoxDecoration(
                      color: isEnabled ? AppColors.accent : AppColors.surface,
                      borderRadius: _boxBorderRadius,
                      border: isEnabled
                          ? null
                          : Border.all(
                              color: AppColors.outline.withValues(alpha: 0.8),
                              width: 1.0,
                            ),
                      boxShadow: isEnabled
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
                          Icons.shuffle_rounded,
                          size: 15.0,
                          color: isEnabled
                              ? AppColors.onAccent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.space6),
                        Text(
                          l10n.shuffle,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: isEnabled
                                ? AppColors.onAccent
                                : AppColors.textSecondary,
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
          const SizedBox(height: AppDimensions.space16),

          // Highlighted Track Count Header anchored directly to the song list below
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.music_note_rounded,
                      size: 14.0,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Text(
                      l10n.songsCount(songCount),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.0,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Container(
                  height: 1.0,
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
