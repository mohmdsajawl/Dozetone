import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

/// Root application widget for Dozetone.
///
/// Sets up MaterialApp.router with Midnight Blue dark theme,
/// localization delegates, and declarative GoRouter navigation.
class DozetoneApp extends StatelessWidget {
  const DozetoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dozetone',
      debugShowCheckedModeBanner: false,

      // Theme configuration (Dark-only for Version 1)
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Navigation routing
      routerConfig: appRouter,

      // Localization delegates generated from ARB files
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
