import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Modal bottom sheet presenting sleep timer duration presets.
class SleepTimerModal extends StatelessWidget {
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

  void _selectPreset(BuildContext context, String durationLabel) {
    Navigator.of(context).pop();

    final l10n = AppLocalizations.of(context)!;
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
                  l10n.timerSetSnackbar(durationLabel),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final presets = <({String label, bool isLastUsed})>[
      (label: l10n.timerPreset15Min, isLastUsed: false),
      (label: l10n.timerPreset30Min, isLastUsed: true),
      (label: l10n.timerPreset45Min, isLastUsed: false),
      (label: l10n.timerPreset60Min, isLastUsed: false),
      (label: l10n.timerEndOfSong, isLastUsed: false),
    ];

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
                    width: 36.0,
                    height: 36.0,
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
                        'Gentle audio fade-out for deep sleep',
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

              // Presets list
              ...presets.map((preset) {
                final accentHighlight =
                    Color.lerp(AppColors.accent, Colors.white, 0.25)!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectPreset(context, preset.label),
                      borderRadius: BorderRadius.circular(14.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                          vertical: AppDimensions.space12,
                        ),
                        decoration: BoxDecoration(
                          color: preset.isLastUsed
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : AppColors.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: preset.isLastUsed
                                ? AppColors.accent.withValues(alpha: 0.4)
                                : AppColors.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.schedule_rounded,
                              size: 18.0,
                              color: preset.isLastUsed
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppDimensions.space12),
                            Expanded(
                              child: Text(
                                preset.label,
                                style: AppTextStyles.body.copyWith(
                                  color: preset.isLastUsed
                                      ? accentHighlight
                                      : AppColors.textPrimary,
                                  fontWeight: preset.isLastUsed
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (preset.isLastUsed)
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
              const SizedBox(height: AppDimensions.space8),
            ],
          ),
        ),
      ),
    );
  }
}
