import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_durations.dart';
import '../../view/library/library_view.dart';
import '../../view/player/now_playing_view.dart';
import '../../view/settings/settings_view.dart';
import '../../view/splash/splash_view.dart';
import 'route_names.dart';

/// Global GoRouter navigation hierarchy for Dozetone.
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splashPath,
  routes: <RouteBase>[
    // Stage 2: Animated Sound Wave Splash screen
    GoRoute(
      path: RouteNames.splashPath,
      name: RouteNames.splash,
      builder: (BuildContext context, GoRouterState state) {
        return const SplashView();
      },
    ),

    // Main local audio music library with 250ms crossfade transition
    GoRoute(
      path: RouteNames.libraryPath,
      name: RouteNames.library,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LibraryView(),
          transitionDuration: AppDurations.pageCrossfade,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
      },
    ),

    // Full-screen Now Playing modal view with 300ms slide-up transition
    GoRoute(
      path: RouteNames.nowPlayingPath,
      name: RouteNames.nowPlaying,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: const NowPlayingView(),
          transitionDuration: AppDurations.nowPlayingSlide,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final tween = Tween(begin: begin, end: end);
            return SlideTransition(
              position: tween.animate(curve),
              child: child,
            );
          },
        );
      },
    ),

    // Settings screen
    GoRoute(
      path: RouteNames.settingsPath,
      name: RouteNames.settings,
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsView();
      },
    ),
  ],
);
