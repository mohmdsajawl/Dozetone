import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'data/services/audio_handler.dart';

/// Entry point of the Dozetone application.
///
/// Sets up:
/// 1. Flutter engine binding initialization
/// 2. Portrait-only orientation lock
/// 3. Edge-to-edge transparent system overlay style
/// 4. Background AudioService handler initialization
/// 5. Riverpod ProviderScope with audio handler injection
Future<void> main() async {
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

  // Initialize background AudioService instance
  final audioHandler = await AudioService.init(
    builder: () => DozetoneAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.velcruxlab.dozetone.channel.audio',
      androidNotificationChannelName: 'Dozetone Playback',
      androidNotificationChannelDescription: 'Active playback controls and timer status',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const DozetoneApp(),
    ),
  );
}
