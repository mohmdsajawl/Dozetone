import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

/// Entry point of the Dozetone application.
///
/// Sets up:
/// 1. Flutter engine binding initialization
/// 2. Portrait-only orientation lock
/// 3. Edge-to-edge transparent system overlay style
/// 4. Riverpod ProviderScope for dependency injection
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode as specified in requirements
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Support edge-to-edge system bars (Android 15) with transparent system overlays
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: DozetoneApp(),
    ),
  );
}
