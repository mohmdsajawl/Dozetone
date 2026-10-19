import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../view_model/sleep_timer/sleep_timer_view_model.dart';
import '../../player/widgets/sleep_timer_modal.dart';

/// Action bar below the Library navbar tabs.
///
/// Houses:
/// 1. Compact left-aligned "Play All" box button.
/// 2. Centered, responsive "Sleep Timer" status & trigger card mimicking Now Playing.
/// 3. Compact right-aligned "Shuffle" box button.
/// Followed by the anchored track count section header.
class LibraryActionBar extends ConsumerWidget {
  final int songCount;
  final VoidCallback onPlayAllTap;
  final VoidCallback onShuffleTap;

  const LibraryActionBar({
    super.key,
    required this.songCount,
    required this.onPlayAllTap,
    required this.onShuffleTap,
  });

  static const double _buttonHeight = 38.0;
  static const BorderRadius _boxBorderRadius =
      BorderRadius.all(Radius.circular(10.0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isEnabled = songCount > 0;
    final sleepTimerState = ref.watch(sleepTimerProvider);

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
          // Actions Row: Play All | Sleep Timer Bar | Shuffle
          Row(
            children: <Widget>[
              // 1. Left-aligned Play All Box Button (compact width)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? onPlayAllTap : null,
                  borderRadius: _boxBorderRadius,
                  child: Container(
                    height: _buttonHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
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
                          size: 19.0,
                          color: isEnabled
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.space4),
                        Text(
                          l10n.playAll,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12.5,
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

              const SizedBox(width: AppDimensions.space8),

              // 2. Middle Sleep Timer Bar (mimicking Now Playing card & function)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => SleepTimerModal.show(context: context),
                    borderRadius: _boxBorderRadius,
                    child: Container(
                      height: _buttonHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: _boxBorderRadius,
                        border: Border.all(
                          color: sleepTimerState.isActive
                              ? AppColors.accent.withValues(alpha: 0.6)
                              : AppColors.outline.withValues(alpha: 0.8),
                          width: 1.0,
                        ),
                        boxShadow: sleepTimerState.isActive
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  blurRadius: 6.0,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: <Widget>[
                          // Small Moon Icon Container
                          Container(
                            width: 24.0,
                            height: 24.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.0),
                              color: sleepTimerState.isActive
                                  ? AppColors.accent.withValues(alpha: 0.25)
                                  : AppColors.accent.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.bedtime_rounded,
                              color: AppColors.accent,
                              size: 14.0,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),

                          // Title and Remaining Countdown / Set Timer Subtitle
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.sleepTimer,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: sleepTimerState.isActive
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  sleepTimerState.isActive
                                      ? (sleepTimerState.isFadingOut
                                          ? l10n.fadingOut
                                          : (sleepTimerState.isTrackBased
                                              ? (sleepTimerState.remainingTracks <= 1
                                                  ? l10n.timerEndOfSong
                                                  : '${sleepTimerState.remainingTracks} tracks')
                                              : (sleepTimerState.isEndOfSong
                                                  ? l10n.timerEndOfSong
                                                  : sleepTimerState.formattedRemaining)))
                                      : 'Set timer',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 10.0,
                                    fontWeight: sleepTimerState.isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: sleepTimerState.isActive
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16.0,
                            color: sleepTimerState.isActive
                                ? AppColors.accent
                                : AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.space8),

              // 3. Right-aligned Shuffle Box Button (compact width)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? onShuffleTap : null,
                  borderRadius: _boxBorderRadius,
                  child: Container(
                    height: _buttonHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
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
                        const SizedBox(width: AppDimensions.space4),
                        Text(
                          l10n.shuffle,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
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
