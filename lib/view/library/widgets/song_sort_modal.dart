import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../view_model/library/library_sort_provider.dart';

/// Modal bottom sheet allowing user to choose active library sort order.
class SongSortModal extends ConsumerWidget {
  const SongSortModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppDimensions.borderRadiusBottomSheet,
      ),
      builder: (context) => const SongSortModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentSort = ref.watch(songSortOrderProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.space16,
          horizontal: AppDimensions.space16,
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
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Header title
            Text(
              l10n.sortBy,
              style: AppTextStyles.screenTitle,
            ),
            const SizedBox(height: AppDimensions.space8),
            const Divider(color: AppColors.outline, height: 1.0),
            const SizedBox(height: AppDimensions.space8),

            // Option 1: Title (A - Z)
            _buildSortOption(
              context: context,
              ref: ref,
              label: '${l10n.sortTitle} (A - Z)',
              order: SongSortOrder.titleAsc,
              isSelected: currentSort == SongSortOrder.titleAsc,
            ),

            // Option 2: Artist (A - Z)
            _buildSortOption(
              context: context,
              ref: ref,
              label: '${l10n.sortArtist} (A - Z)',
              order: SongSortOrder.artistAsc,
              isSelected: currentSort == SongSortOrder.artistAsc,
            ),

            // Option 3: Duration (Longest first)
            _buildSortOption(
              context: context,
              ref: ref,
              label: '${l10n.sortDuration} (Longest first)',
              order: SongSortOrder.durationDesc,
              isSelected: currentSort == SongSortOrder.durationDesc,
            ),

            // Option 4: Date added (Newest first)
            _buildSortOption(
              context: context,
              ref: ref,
              label: l10n.sortDateAdded,
              order: SongSortOrder.dateAddedDesc,
              isSelected: currentSort == SongSortOrder.dateAddedDesc,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required SongSortOrder order,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: isSelected ? AppColors.accent : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: isSelected
            ? AppTextStyles.body.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              )
            : AppTextStyles.body,
      ),
      onTap: () {
        ref.read(songSortOrderProvider.notifier).state = order;
        Navigator.of(context).pop();
      },
    );
  }
}
