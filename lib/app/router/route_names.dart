/// Central route name constants for GoRouter.
///
/// Ensures type-safe navigation without raw string routes.
abstract final class RouteNames {
  /// Initial animated splash screen route.
  static const String splash = 'splash';
  static const String splashPath = '/';

  /// Primary music library screen route.
  static const String library = 'library';
  static const String libraryPath = '/library';

  /// Now Playing full-screen modal player route.
  static const String nowPlaying = 'now_playing';
  static const String nowPlayingPath = '/now-playing';

  /// Application settings screen route.
  static const String settings = 'settings';
  static const String settingsPath = '/settings';
}
