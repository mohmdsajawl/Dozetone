import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../widgets/sound_wave_rings.dart';

/// State View: Permission required to access device audio files.
class PermissionRequiredView extends StatelessWidget {
  final bool isPermanentlyDenied;
  final VoidCallback onGrantTap;
  final VoidCallback onSettingsTap;

  const PermissionRequiredView({
    super.key,
    required this.isPermanentlyDenied,
    required this.onGrantTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 36.0,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
            Text(
              l10n.permissionRequired,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space24),
            ElevatedButton(
              onPressed: isPermanentlyDenied ? onSettingsTap : onGrantTap,
              child: Text(
                isPermanentlyDenied ? l10n.openSettings : l10n.grantPermission,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// State View: Actively scanning device storage for audio tracks.
///
/// Features the custom continuous acoustic expanding rings pulse animation
/// emanating from the brand D mark instead of a generic circular spinner.
class ScanningSongsView extends StatelessWidget {
  const ScanningSongsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Expanding Sound Wave ripple rings around brand mark
          const SoundWavePulseLoader(size: 72.0),
          const SizedBox(height: AppDimensions.space24),

          // Scanning indicator text
          Text(
            l10n.scanningMusic,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

/// State View: No songs found on device matching criteria.
class EmptyLibraryView extends StatelessWidget {
  const EmptyLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline),
              ),
              child: const Icon(
                Icons.music_off_rounded,
                size: 36.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
            Text(
              l10n.noSongsFound,
              style: AppTextStyles.screenTitle,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              l10n.shortSongsHiddenHint,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// State View: Search query yielded zero matching tracks.
class NoSearchResultsView extends StatelessWidget {
  final String query;

  const NoSearchResultsView({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              size: 48.0,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              l10n.noSearchResults(query),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// State View: Query or storage read error occurred.
class ErrorLibraryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorLibraryView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 48.0,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space24),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
