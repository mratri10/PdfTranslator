import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class BookStorageService {
  static const String folderName = 'book-pdf';

  static Future<String> getBookFolderPath() async {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return '/storage/emulated/0/$folderName';
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      return '${docDir.path}/$folderName';
    }
  }

  static Future<bool> checkFolderExists() async {
    if (kIsWeb) return false;
    try {
      final path = await getBookFolderPath();
      return await Directory(path).exists();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      // Check if manageExternalStorage is already granted
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      // Request manageExternalStorage for Android 11+
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      // Fallback for Android 10 and below
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      return false;
    }
    return true; // No permission required on other desktop/iOS (path_provider acts within sandboxes)
  }

  static Future<bool> createBookFolder() async {
    if (kIsWeb) return false;
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return false;

      final path = await getBookFolderPath();
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return true;
    } catch (e) {
      debugPrint('Error creating book folder: $e');
      return false;
    }
  }

  static Future<List<File>> getBookList() async {
    if (kIsWeb) return [];
    try {
      final path = await getBookFolderPath();
      final dir = Directory(path);
      if (await dir.exists()) {
        final files = dir.listSync();
        return files
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.pdf'))
            .toList();
      }
    } catch (e) {
      debugPrint('Error listing files in book folder: $e');
    }
    return [];
  }
}
