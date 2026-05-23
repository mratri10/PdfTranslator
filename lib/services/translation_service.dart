import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class TranslationService {
  /// Translates text using the CORS-friendly Google Translation endpoint.
  /// If it fails, it falls back to the `translator` package.
  static Future<String> translate(String text, String targetLang) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return '';

    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(trimmedText)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded != null && decoded is List && decoded.isNotEmpty) {
          final segments = decoded[0];
          if (segments != null && segments is List) {
            final translatedText = segments
                .map((segment) => (segment is List && segment.isNotEmpty)
                    ? segment[0].toString()
                    : '')
                .join('');
            if (translatedText.isNotEmpty) {
              return translatedText;
            }
          }
        }
      }
      throw Exception('Invalid translation response schema');
    } catch (e) {
      // Fallback to the native translator package
      try {
        final translator = GoogleTranslator();
        final translation = await translator.translate(trimmedText, to: targetLang);
        return translation.text;
      } catch (fallbackError) {
        // Return a combined clean error message
        throw Exception('Translation error: $e (Fallback error: $fallbackError)');
      }
    }
  }
}
