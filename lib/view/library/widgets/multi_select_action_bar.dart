import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Contextual Top App Bar displayed when songs multi-select mode is active.
///
/// Provides exit/cancel button, selected items count, and a one-tap
/// "Select All" / "Deselect All" action.
class MultiSelectActionBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onCancel;
  final VoidCallback onSelectAllToggle;

  const MultiSelectActionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onCancel,
    required this.onSelectAllToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8.0);

  bool get isAllSelected => selectedCount > 0 && selectedCount == totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        left: AppDimensions.space8,
        right: AppDimensions.space8,
      ),
      child: SizedBox(
        height: kToolbarHeight + 8.0,
        child: Row(
          children: <Widget>[
            // Exit selection mode button
            IconButton(
              icon: const Icon(Icons.close_rounded),
              iconSize: 24.0,
              color: AppColors.textPrimary,
              tooltip: 'Cancel',
              onPressed: () {
                HapticFeedback.lightImpact();
                onCancel();
              },
            ),
            const SizedBox(width: AppDimensions.space8),

            // Counter label
            Expanded(
              child: Text(
                '$selectedCount selected',
                style: AppTextStyles.screenTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.0,
                ),
              ),
            ),

            // Select All / Deselect All button
            TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onSelectAllToggle();
              },
              icon: Icon(
                isAllSelected
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
                size: 20.0,
                color: AppColors.accent,
              ),
              label: Text(
                isAllSelected ? 'Deselect All' : 'Select All',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space12,
                  vertical: AppDimensions.space8,
                ),
                backgroundColor: AppColors.surface.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: AppColors.outline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
