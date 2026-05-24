import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:pdf_translator/firebase_options.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static bool _initialized = false;

  /// Initializes Firebase and Firebase Analytics safely.
  /// Catches and logs any configuration or permission errors.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _analytics = FirebaseAnalytics.instance;
      _initialized = true;
      debugPrint('[AnalyticsService] Firebase initialized successfully.');
    } catch (e, stack) {
      debugPrint('[AnalyticsService] Failed to initialize Firebase: $e');
      debugPrint('$stack');
    }
  }

  /// Logs a custom event safely.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('[AnalyticsService] Event logged: $name $parameters');
    } catch (e) {
      debugPrint('[AnalyticsService] Failed to log event $name: $e');
    }
  }

  /// Logs app startup.
  static Future<void> logAppLaunch() async {
    await logEvent(name: 'app_launch');
  }

  /// Logs when a PDF file is opened/picked.
  static Future<void> logBookOpened(String fileName, int sizeBytes) async {
    await logEvent(
      name: 'book_opened',
      parameters: {
        'file_name': fileName,
        'file_size_bytes': sizeBytes,
      },
    );
  }

  /// Logs translation triggers.
  static Future<void> logTranslation({
    required int textLength,
    required String targetLang,
  }) async {
    await logEvent(
      name: 'translation_triggered',
      parameters: {
        'text_length': textLength,
        'target_language': targetLang,
      },
    );
  }

  /// Logs page reading progress.
  static Future<void> logPageReadProgress({
    required String bookKey,
    required int pageNumber,
  }) async {
    await logEvent(
      name: 'read_progress',
      parameters: {
        'book_key': bookKey.split('/').last, // Keep it anonymous/short
        'page_number': pageNumber,
      },
    );
  }

  /// Logs any caught errors or failures to monitor app stability.
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage.substring(
          0,
          errorMessage.length > 100 ? 100 : errorMessage.length,
        ),
        if (stackTrace != null)
          'stack_trace': stackTrace.substring(
            0,
            stackTrace.length > 100 ? 100 : stackTrace.length,
          ),
      },
    );
  }
}
