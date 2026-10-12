import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../view_model/library/library_search_query_provider.dart';

/// Top app bar header for the Song Library.
///
/// Seamlessly animates between displaying the Dozetone brand wordmark
/// and an interactive search text field with 200 ms debounce.
class LibraryHeader extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final VoidCallback onSettingsTap;

  const LibraryHeader({
    super.key,
    required this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8.0);

  @override
  ConsumerState<LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends ConsumerState<LibraryHeader> {
  bool _isSearching = false;
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppDurations.searchDebounce, () {
      ref.read(libraryQueryProvider.notifier).state = value;
    });
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(libraryQueryProvider.notifier).state = '';
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: widget.preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: AppDurations.uiChange,
            child: _isSearching
                ? _buildSearchField(l10n)
                : _buildStandardHeader(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardHeader(AppLocalizations l10n) {
    return Row(
      key: const ValueKey<String>('standard_header'),
      children: <Widget>[
        // Wordmark brand logo on left
        SvgPicture.asset(
          AppAssets.logoSvg,
          height: AppDimensions.logoHeaderHeight,
          colorFilter: const ColorFilter.mode(
            AppColors.accent,
            BlendMode.srcIn,
          ),
        ),
        const Spacer(),

        // Search trigger button
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: l10n.searchPlaceholder,
          color: AppColors.textPrimary,
          onPressed: _openSearch,
        ),

        // Settings trigger button
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: l10n.settingsTitle,
          color: AppColors.textPrimary,
          onPressed: widget.onSettingsTap,
        ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return Row(
      key: const ValueKey<String>('search_header'),
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: AppTextStyles.body,
            cursorColor: AppColors.accent,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              hintStyle: AppTextStyles.bodySecondary,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              border: OutlineInputBorder(
                borderRadius: AppDimensions.borderRadiusCard,
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppDimensions.borderRadiusCard,
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppDimensions.borderRadiusCard,
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 20.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.cancel,
          color: AppColors.textSecondary,
          onPressed: _closeSearch,
        ),
      ],
    );
  }
}
