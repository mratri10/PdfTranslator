import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:permission_handler/permission_handler.dart';

/// Result of a permission check / request.
enum StoragePermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  notRequired, // web or non-Android platform
}

class PermissionService {
  /// Returns the current storage permission status without requesting.
  static Future<StoragePermissionStatus> checkStoragePermission() async {
    if (kIsWeb) return StoragePermissionStatus.notRequired;
    if (!Platform.isAndroid) return StoragePermissionStatus.notRequired;

    // Android 11+ uses MANAGE_EXTERNAL_STORAGE
    if (await Permission.manageExternalStorage.isGranted) {
      return StoragePermissionStatus.granted;
    }
    // Legacy READ_EXTERNAL_STORAGE (Android ≤ 9)
    if (await Permission.storage.isGranted) {
      return StoragePermissionStatus.granted;
    }

    if (await Permission.manageExternalStorage.isPermanentlyDenied) {
      return StoragePermissionStatus.permanentlyDenied;
    }

    return StoragePermissionStatus.denied;
  }

  /// Requests storage permission and returns the resulting status.
  static Future<StoragePermissionStatus> requestStoragePermission() async {
    if (kIsWeb) return StoragePermissionStatus.notRequired;
    if (!Platform.isAndroid) return StoragePermissionStatus.notRequired;

    // Try MANAGE_EXTERNAL_STORAGE first (Android 11+)
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return StoragePermissionStatus.granted;
    if (status.isPermanentlyDenied) return StoragePermissionStatus.permanentlyDenied;

    // Fallback to legacy READ/WRITE_EXTERNAL_STORAGE (Android ≤ 9)
    status = await Permission.storage.request();
    if (status.isGranted) return StoragePermissionStatus.granted;
    if (status.isPermanentlyDenied) return StoragePermissionStatus.permanentlyDenied;

    debugPrint('[PermissionService] Storage permission denied.');
    return StoragePermissionStatus.denied;
  }

  /// Opens the app settings page so the user can manually enable permissions.
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
