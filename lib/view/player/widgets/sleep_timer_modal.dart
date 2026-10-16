import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../model/sleep_timer_state.dart';
import '../../../view_model/sleep_timer/sleep_timer_view_model.dart';

/// Modal bottom sheet presenting sleep timer presets and active countdown controls.
class SleepTimerModal extends ConsumerWidget {
  const SleepTimerModal({super.key});

  /// Displays the Sleep Timer modal bottom sheet.
  static Future<void> show({required BuildContext context}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const SleepTimerModal(),
    );
  }

  void _startPresetTimer({
    required BuildContext context,
    required WidgetRef ref,
    required Duration duration,
    required String label,
  }) {
    Navigator.of(context).pop();
    ref.read(sleepTimerProvider.notifier).startTimer(duration, choiceLabel: label);

    final l10n = AppLocalizations.of(context)!;
    _showTimerSnackbar(context, l10n.timerSetSnackbar(label));
  }

  void _startEndOfSongTimer({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
  }) {
    Navigator.of(context).pop();
    ref.read(sleepTimerProvider.notifier).startEndOfSongTimer(choiceLabel: label);

    final l10n = AppLocalizations.of(context)!;
    _showTimerSnackbar(context, l10n.timerSetSnackbar(label));
  }

  Future<void> _showCustomDurationDialog({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    int selectedMinutes = 20;

    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                l10n.timerCustom,
                style: AppTextStyles.screenTitle,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$selectedMinutes minutes',
                    style: AppTextStyles.screenTitle.copyWith(
                      color: AppColors.accent,
                      fontSize: 28.0,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.outline,
                      thumbColor: AppColors.textPrimary,
                    ),
                    child: Slider(
                      value: selectedMinutes.toDouble(),
                      min: 1.0,
                      max: 240.0,
                      divisions: 239,
                      label: '$selectedMinutes min',
                      onChanged: (val) {
                        setDialogState(() {
                          selectedMinutes = val.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selectedMinutes),
                  child: const Text(
                    'Set',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null && context.mounted) {
      final label = '$picked minutes';
      _startPresetTimer(
        context: context,
        ref: ref,
        duration: Duration(minutes: picked),
        label: label,
      );
    }
  }

  void _showTimerSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(
                Icons.bedtime_rounded,
                color: AppColors.accent,
                size: 20.0,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final timerState = ref.watch(sleepTimerProvider);
    final viewModel = ref.read(sleepTimerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusBottomSheet,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Drag handle
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
              const SizedBox(height: AppDimensions.space16),

              // Header: Moon icon + Title
              Row(
                children: <Widget>[
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.bedtime_rounded,
                      color: AppColors.accent,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.sleepTimer,
                        style: AppTextStyles.screenTitle.copyWith(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timerState.isActive
                            ? 'Timer in progress'
                            : 'Gentle audio fade-out for deep sleep',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space24),

              if (timerState.isActive)
                _buildActiveTimerView(context, ref, l10n, timerState, viewModel)
              else
                _buildPresetsListView(context, ref, l10n, timerState),
            ],
          ),
        ),
      ),
    );
  }

  /// Active countdown view with big digits, fade indicator, and action buttons.
  Widget _buildActiveTimerView(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SleepTimerState timerState,
    SleepTimerViewModel viewModel,
  ) {
    return Column(
      children: <Widget>[
        // Large countdown clock
        Center(
          child: Column(
            children: <Widget>[
              Text(
                timerState.formattedRemaining,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 48.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),

              // Fade-out status indicator badge
              if (timerState.isFadingOut)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: AppDimensions.borderRadiusPill,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.graphic_eq_rounded,
                        size: 14.0,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppDimensions.space6),
                      Text(
                        l10n.fadingOut,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Music will gently fade out',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.0,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space32),

        // Action Buttons: +5 min and Cancel timer
        Row(
          children: <Widget>[
            // +5 Min Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: viewModel.add5Minutes,
                icon: const Icon(Icons.add_rounded, size: 20.0),
                label: Text(l10n.add5Min),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
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
            const SizedBox(width: AppDimensions.space12),

            // Cancel Timer Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  viewModel.cancelTimer();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close_rounded, size: 20.0),
                label: Text(l10n.cancelTimer),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.space12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (timerState.shakeToExtendEnabled) ...<Widget>[
          const SizedBox(height: AppDimensions.space12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space12,
              vertical: AppDimensions.space8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.vibration_rounded,
                  size: 16.0,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppDimensions.space8),
                Text(
                  l10n.shakeToExtendHint,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.space16),
      ],
    );
  }

  /// Preset choices view when timer is not currently active.
  Widget _buildPresetsListView(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SleepTimerState timerState,
  ) {
    final presets = <({String label, Duration? duration, bool isEndOfSong, bool isCustom})>[
      (label: l10n.timerPreset5Min, duration: const Duration(minutes: 5), isEndOfSong: false, isCustom: false),
      (label: l10n.timerPreset10Min, duration: const Duration(minutes: 10), isEndOfSong: false, isCustom: false),
      (label: l10n.timerPreset15Min, duration: const Duration(minutes: 15), isEndOfSong: false, isCustom: false),
      (label: l10n.timerPreset30Min, duration: const Duration(minutes: 30), isEndOfSong: false, isCustom: false),
      (label: l10n.timerPreset45Min, duration: const Duration(minutes: 45), isEndOfSong: false, isCustom: false),
      (label: l10n.timerPreset60Min, duration: const Duration(minutes: 60), isEndOfSong: false, isCustom: false),
      (label: l10n.timerCustom, duration: null, isEndOfSong: false, isCustom: true),
      (label: l10n.timerEndOfSong, duration: null, isEndOfSong: true, isCustom: false),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.58,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ...presets.map((preset) {
              final isLastUsed = timerState.lastUsedChoice != null &&
                  timerState.lastUsedChoice == preset.label;
              final accentHighlight =
                  Color.lerp(AppColors.accent, Colors.white, 0.25)!;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (preset.isCustom) {
                        _showCustomDurationDialog(context: context, ref: ref);
                      } else if (preset.isEndOfSong) {
                        _startEndOfSongTimer(
                          context: context,
                          ref: ref,
                          label: preset.label,
                        );
                      } else if (preset.duration != null) {
                        _startPresetTimer(
                          context: context,
                          ref: ref,
                          duration: preset.duration!,
                          label: preset.label,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: AppDimensions.space12,
                      ),
                      decoration: BoxDecoration(
                        color: isLastUsed
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: isLastUsed
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : AppColors.outline.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            preset.isEndOfSong
                                ? Icons.music_note_rounded
                                : preset.isCustom
                                    ? Icons.tune_rounded
                                    : Icons.schedule_rounded,
                            size: 18.0,
                            color: isLastUsed
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: Text(
                              preset.label,
                              style: AppTextStyles.body.copyWith(
                                color: isLastUsed
                                    ? accentHighlight
                                    : AppColors.textPrimary,
                                fontWeight: isLastUsed
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isLastUsed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.space8,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: AppDimensions.borderRadiusPill,
                              ),
                              child: Text(
                                l10n.lastUsed,
                                style: AppTextStyles.caption.copyWith(
                                  color: accentHighlight,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppDimensions.space4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.vibration_rounded,
                    size: 18.0,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.shakeToExtendTitle,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.0,
                          ),
                        ),
                        Text(
                          l10n.shakeToExtendHint,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: timerState.shakeToExtendEnabled,
                    activeThumbColor: AppColors.accent,
                    onChanged: (val) {
                      ref
                          .read(sleepTimerProvider.notifier)
                          .setShakeToExtend(val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
