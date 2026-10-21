import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../view_model/settings/settings_view_model.dart';

/// Settings screen for Dozetone.
///
/// Configures audio filtering (WhatsApp voice notes exclusion),
/// sleep timer behavior (gentle fade-out, shake to extend),
/// and general playback preferences.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsViewModelProvider);
    final viewModel = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(l10n.settingsTitle, style: AppTextStyles.screenTitle),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: 12.0,
        ),
        children: [
          // Section 1: Library & Audio Filtering
          _buildSectionHeader(l10n.libraryAndFiltering),
          const SizedBox(height: 8.0),
          _buildSettingsCard(
            children: [
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                activeThumbColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.outline,
                secondary: const Icon(
                  Icons.voice_over_off_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  l10n.ignoreWhatsappTitle,
                  style: AppTextStyles.songTitle,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    l10n.ignoreWhatsappSubtitle,
                    style: AppTextStyles.caption,
                  ),
                ),
                value: settings.excludeWhatsapp,
                onChanged: (val) {
                  viewModel.toggleExcludeWhatsapp(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val
                            ? l10n.whatsappHiddenSnackbar
                            : l10n.whatsappVisibleSnackbar,
                        style: AppTextStyles.body,
                      ),
                      backgroundColor: AppColors.surface,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.outline, height: 1.0, indent: 56.0),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                leading: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  l10n.minimumTrackDurationTitle,
                  style: AppTextStyles.songTitle,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    l10n.minimumTrackDurationSubtitle,
                    style: AppTextStyles.caption,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softAccent(0.12),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    '30s',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // Section 2: Sleep Timer Preferences
          _buildSectionHeader(l10n.sleepTimer),
          const SizedBox(height: 8.0),
          _buildSettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                leading: const Icon(
                  Icons.volume_down_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  l10n.gentleFadeOutDurationTitle,
                  style: AppTextStyles.songTitle,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    l10n.gentleFadeOutDurationSubtitle,
                    style: AppTextStyles.caption,
                  ),
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: settings.fadeSeconds,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.accent,
                    ),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15s')),
                      DropdownMenuItem(value: 30, child: Text('30s')),
                      DropdownMenuItem(value: 60, child: Text('60s')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        viewModel.setFadeSeconds(val);
                      }
                    },
                  ),
                ),
              ),
              const Divider(color: AppColors.outline, height: 1.0, indent: 56.0),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                activeThumbColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.outline,
                secondary: const Icon(
                  Icons.vibration_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  l10n.shakeToExtendTitle,
                  style: AppTextStyles.songTitle,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    l10n.shakeToExtendSubtitle,
                    style: AppTextStyles.caption,
                  ),
                ),
                value: settings.shakeToExtend,
                onChanged: (val) => viewModel.toggleShakeToExtend(val),
              ),
              const Divider(color: AppColors.outline, height: 1.0, indent: 56.0),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                activeThumbColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.outline,
                secondary: const Icon(
                  Icons.trending_down_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  l10n.slowVolumeDeclineTitle,
                  style: AppTextStyles.songTitle,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    l10n.slowVolumeDeclineSubtitle,
                    style: AppTextStyles.caption,
                  ),
                ),
                value: settings.slowVolumeDecline,
                onChanged: (val) => viewModel.toggleSlowVolumeDecline(val),
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // Section 3: Bedtime Auto-Timer
          _buildSectionHeader(l10n.bedtimeAutoTimerSection),
          const SizedBox(height: 8.0),
          _buildSettingsCard(
            children: [
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                activeThumbColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.outline,
                secondary: const Icon(
                  Icons.bedtime_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  l10n.autoStartSleepTimerTitle,
                  style: AppTextStyles.songTitle,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    l10n.autoStartSleepTimerSubtitle,
                    style: AppTextStyles.caption,
                  ),
                ),
                value: settings.bedtimeAutoTimer,
                onChanged: (val) => viewModel.toggleBedtimeAutoTimer(val),
              ),
              if (settings.bedtimeAutoTimer) ...[
                const Divider(color: AppColors.outline, height: 1.0, indent: 56.0),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  leading: const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    l10n.bedtimeStartsAtTitle,
                    style: AppTextStyles.songTitle,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      l10n.bedtimeStartsAtSubtitle,
                      style: AppTextStyles.caption,
                    ),
                  ),
                  trailing: InkWell(
                    borderRadius: BorderRadius.circular(10.0),
                    onTap: () async {
                      final currentHour = settings.bedtimeStartMinutes ~/ 60;
                      final currentMinute = settings.bedtimeStartMinutes % 60;
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: currentHour,
                          minute: currentMinute,
                        ),
                      );
                      if (picked != null) {
                        viewModel.setBedtimeStartMinutes(
                          picked.hour * 60 + picked.minute,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softAccent(0.12),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        settings.formattedBedtimeStart,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(color: AppColors.outline, height: 1.0, indent: 56.0),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  leading: const Icon(
                    Icons.timelapse_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    l10n.autoTimerDurationTitle,
                    style: AppTextStyles.songTitle,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      l10n.autoTimerDurationSubtitle,
                      style: AppTextStyles.caption,
                    ),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: settings.bedtimeDurationMinutes,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.accent,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 15,
                          child: Text(l10n.customMinutesLabel(15)),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text(l10n.customMinutesLabel(30)),
                        ),
                        DropdownMenuItem(
                          value: 45,
                          child: Text(l10n.customMinutesLabel(45)),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text(l10n.customMinutesLabel(60)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          viewModel.setBedtimeDurationMinutes(val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24.0),

          // Section 4: About
          _buildSectionHeader(l10n.aboutSection),
          const SizedBox(height: 8.0),
          _buildSettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                leading: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: AppColors.softAccent(0.15),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    color: AppColors.accent,
                    size: 22.0,
                  ),
                ),
                title: const Text(
                  'Dozetone',
                  style: AppTextStyles.songTitle,
                ),
                subtitle: Text(
                  l10n.appTaglineVersion('1.0.0'),
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40.0),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.6),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
