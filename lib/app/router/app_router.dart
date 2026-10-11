import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'route_names.dart';

/// Global GoRouter instance configured for Dozetone navigation.
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splashPath,
  routes: <RouteBase>[
    GoRoute(
      path: RouteNames.splashPath,
      name: RouteNames.splash,
      builder: (BuildContext context, GoRouterState state) {
        return const _FoundationPlaceholderScreen();
      },
    ),
  ],
);

/// Themed placeholder screen demonstrating active Material 3 Midnight Blue theme.
class _FoundationPlaceholderScreen extends StatelessWidget {
  const _FoundationPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: AppDimensions.splashMarkWidth,
                  height: AppDimensions.splashMarkWidth,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimensions.borderRadiusArtworkLarge,
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.nightlight_round,
                      color: AppColors.accent,
                      size: 48.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),
                const Text(
                  'Dozetone',
                  style: AppTextStyles.screenTitle,
                ),
                const SizedBox(height: AppDimensions.space8),
                const Text(
                  'Phase 0: Foundation Ready',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
