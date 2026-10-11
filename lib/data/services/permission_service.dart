import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Provider for accessing the PermissionService instance.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return const PermissionService();
});

/// Service responsible for managing device audio storage permissions.
///
/// Handles Android 13+ (API 33+) READ_MEDIA_AUDIO and Android 12 and below
/// READ_EXTERNAL_STORAGE permissions.
class PermissionService {
  const PermissionService();

  /// Gets the appropriate storage permission based on Android platform.
  Permission get _audioPermission {
    if (Platform.isAndroid) {
      // permission_handler automatically maps Permission.audio to READ_MEDIA_AUDIO
      return Permission.audio;
    }
    return Permission.storage;
  }

  /// Checks whether audio read permission is currently granted.
  Future<bool> isAudioPermissionGranted() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final audioStatus = await _audioPermission.status;
    if (audioStatus.isGranted || audioStatus.isLimited) {
      return true;
    }

    // For Android 12 and below where Permission.audio may not apply
    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted || storageStatus.isLimited;
  }

  /// Requests audio permission from the user.
  ///
  /// Returns the resolved permission status.
  Future<PermissionStatus> requestAudioPermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }

    // Attempt requesting Android 13+ audio permission first
    var status = await _audioPermission.request();
    if (status.isGranted || status.isLimited) {
      return status;
    }

    // If audio permission is not applicable (e.g. Android 12 and below), request storage
    if (status.isDenied || status.isPermanentlyDenied) {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted || storageStatus.isLimited) {
        return storageStatus;
      }
      return storageStatus.isPermanentlyDenied ? storageStatus : status;
    }

    return status;
  }

  /// Checks if permission is permanently denied (user selected "Don't ask again").
  Future<bool> isPermanentlyDenied() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final audioPermanentlyDenied = await _audioPermission.isPermanentlyDenied;
    final storagePermanentlyDenied = await Permission.storage.isPermanentlyDenied;

    return audioPermanentlyDenied || storagePermanentlyDenied;
  }

  /// Opens the device application settings screen.
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
