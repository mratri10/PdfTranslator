import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_translator/models/reader_theme.dart';
import 'package:pdf_translator/services/translation_service.dart';
import 'package:pdf_translator/services/book_storage_service.dart';
import 'package:pdf_translator/services/analytics_service.dart';

enum PdfPageFilter { none, sepia, invert, monochrome }

enum ReaderInteractionMode { selection, pan }

class ReaderProvider extends ChangeNotifier {
  PlatformFile? _selectedFile;
  bool _isFileLoading = false;
  String? _fileError;

  String _originalText = '';
  String _translatedText = '';
  String _selectedText = '';
  bool _isTranslating = false;
  String? _translationError;

  /// Callback registered by PdfViewPane to clear the PDF text selection highlight.
  VoidCallback? _onClearPdfSelection;

  // Interaction Mode (default to selection for desktop web usability)
  ReaderInteractionMode _interactionMode = ReaderInteractionMode.selection;

  // Translation configuration
  String _targetLanguage = 'id'; // default: Indonesian
  double _translationFontSize = 16.0;

  // Selected Theme (default is Sepia Paper)
  ReaderTheme _currentTheme = ReaderTheme.allThemes.firstWhere(
    (t) => t.type == ReaderThemeType.sepia,
    orElse: () => ReaderTheme.allThemes.first,
  );

  // PDF Page color filter (defaults to none, but changes based on theme)
  PdfPageFilter _pdfFilter = PdfPageFilter.none;

  // Book-like rendering configuration
  bool _isBookMode = false;

  // Local storage lists for books (Android feature)
  List<io.File> _localBooks = [];
  bool _isStoragePermissionGranted = false;
  bool _bookFolderExists = false;

  ReaderProvider() {
    initLocalBooks();
  }

  // Getters
  PlatformFile? get selectedFile => _selectedFile;
  bool get isFileLoading => _isFileLoading;
  String? get fileError => _fileError;

  String get originalText => _originalText;
  String get translatedText => _translatedText;
  String get selectedText => _selectedText;
  bool get isTranslating => _isTranslating;
  String? get translationError => _translationError;

  ReaderInteractionMode get interactionMode => _interactionMode;
  String get targetLanguage => _targetLanguage;
  double get translationFontSize => _translationFontSize;
  ReaderTheme get currentTheme => _currentTheme;
  PdfPageFilter get pdfFilter => _pdfFilter;

  bool get isBookMode => _isBookMode;
  List<io.File> get localBooks => _localBooks;
  bool get isStoragePermissionGranted => _isStoragePermissionGranted;
  bool get bookFolderExists => _bookFolderExists;

  void toggleBookMode() {
    _isBookMode = !_isBookMode;
    notifyListeners();
  }

  Future<void> initLocalBooks() async {
    if (kIsWeb) return;
    _bookFolderExists = await BookStorageService.checkFolderExists();
    if (_bookFolderExists) {
      _localBooks = await BookStorageService.getBookList();
      _isStoragePermissionGranted = true;
    }
    notifyListeners();
  }

  Future<void> createBookFolder() async {
    if (kIsWeb) return;
    final created = await BookStorageService.createBookFolder();
    if (created) {
      _bookFolderExists = true;
      _isStoragePermissionGranted = true;
      _localBooks = await BookStorageService.getBookList();
    }
    notifyListeners();
  }

  Future<void> refreshLocalBooks() async {
    if (kIsWeb) return;
    _bookFolderExists = await BookStorageService.checkFolderExists();
    if (_bookFolderExists) {
      _isStoragePermissionGranted = true;
      _localBooks = await BookStorageService.getBookList();
    }
    notifyListeners();
  }

  Future<void> selectLocalBook(io.File file) async {
    _isFileLoading = true;
    _fileError = null;
    notifyListeners();

    try {
      final name = file.path.split('/').last;
      final size = await file.length();
      _selectedFile = PlatformFile(name: name, size: size, path: file.path);
      _originalText = '';
      _translatedText = '';
      _translationError = null;
      _syncPdfFilterWithTheme();
    } catch (e, stack) {
      _fileError = 'Gagal memuat buku: $e';
      AnalyticsService.logError(
        errorType: 'ReaderProvider_selectLocalBook',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
    } finally {
      _isFileLoading = false;
      notifyListeners();
    }
  }

  void toggleInteractionMode() {
    _interactionMode = _interactionMode == ReaderInteractionMode.selection
        ? ReaderInteractionMode.pan
        : ReaderInteractionMode.selection;
    notifyListeners();
  }

  // Target languages list
  final Map<String, String> supportedLanguages = {
    'id': 'Bahasa Indonesia',
    'en': 'English',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
    'de': 'Deutsch (German)',
    'ja': '日本語 (Japanese)',
    'zh': '中文 (Chinese)',
    'ar': 'العربية (Arabic)',
    'ru': 'Русский (Russian)',
  };

  /// Pick a PDF file using FilePicker
  Future<void> pickPdfFile() async {
    _isFileLoading = true;
    _fileError = null;
    notifyListeners();

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        // Only load bytes on Web — on Android/Desktop the file path is sufficient.
        // Loading bytes on Android causes double memory pressure (Dart heap + Syncfusion native)
        // which can trigger an ANR on large PDF files.
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.name.toLowerCase().endsWith('.pdf')) {
          _selectedFile = file;
          _originalText = '';
          _translatedText = '';
          _translationError = null;

          // Auto-adjust page filter for night themes when a new file is loaded
          _syncPdfFilterWithTheme();
        } else {
          _fileError = 'Format file tidak didukung. Pilih file PDF.';
        }
      }
    } catch (e, stack) {
      _fileError = 'Gagal memuat file: $e';
      AnalyticsService.logError(
        errorType: 'ReaderProvider_pickPdfFile',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
    } finally {
      _isFileLoading = false;
      notifyListeners();
    }
  }

  /// Close the current file
  void clearFile() {
    _selectedFile = null;
    _originalText = '';
    _translatedText = '';
    _fileError = null;
    _translationError = null;
    _selectedText = '';
    notifyListeners();
  }

  /// Register a callback to clear the PDF viewer's text selection.
  /// Called by PdfViewPane in initState / dispose.
  void registerClearSelectionCallback(VoidCallback callback) {
    _onClearPdfSelection = callback;
  }

  void unregisterClearSelectionCallback() {
    _onClearPdfSelection = null;
  }

  /// Reset translation state and clear the PDF text-selection highlight.
  void clearTranslation() {
    _originalText = '';
    _translatedText = '';
    _translationError = null;
    _selectedText = '';
    _onClearPdfSelection?.call(); // clear drag-selection in viewer
    notifyListeners();
  }

  /// Update active text selection
  void setSelectedText(String text) {
    _selectedText = text;
    notifyListeners();
  }

  /// Clear active text selection
  void clearSelectedText() {
    _selectedText = '';
    notifyListeners();
  }

  /// Change theme
  void changeTheme(ReaderTheme theme) {
    _currentTheme = theme;
    // Auto-match PDF page filter with theme for a better reader experience
    _syncPdfFilterWithTheme();
    notifyListeners();
  }

  /// Sync PDF filter with the current theme to support long-time reading
  void _syncPdfFilterWithTheme() {
    if (_currentTheme.type == ReaderThemeType.solarizedDark ||
        _currentTheme.type == ReaderThemeType.charcoalNight) {
      _pdfFilter = PdfPageFilter.invert;
    } else if (_currentTheme.type == ReaderThemeType.sepia) {
      _pdfFilter = PdfPageFilter.sepia;
    } else {
      _pdfFilter = PdfPageFilter.none;
    }
  }

  /// Change PDF page filter
  void changePdfFilter(PdfPageFilter filter) {
    _pdfFilter = filter;
    notifyListeners();
  }

  /// Update target translation language
  void changeTargetLanguage(String langCode) {
    if (supportedLanguages.containsKey(langCode)) {
      _targetLanguage = langCode;
      notifyListeners();
      // If we already have copied text, re-translate it to the new language
      if (_originalText.isNotEmpty) {
        translateText(_originalText);
      }
    }
  }

  /// Update font size for the translation box
  void changeFontSize(double size) {
    if (size >= 12.0 && size <= 28.0) {
      _translationFontSize = size;
      notifyListeners();
    }
  }

  /// Checks clipboard contents silently and auto-translates if new text is copied
  Future<void> checkClipboardAndTranslate() async {
    if (_isTranslating) return;
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      if (text != null && text.isNotEmpty && text != _originalText) {
        _isTranslating = true;
        _translationError = null;
        notifyListeners();

        _originalText = text;
        AnalyticsService.logTranslation(
          textLength: text.length,
          targetLang: _targetLanguage,
        );
        _translatedText = await TranslationService.translate(text, _targetLanguage);
      }
    } catch (e, stack) {
      // Silently ignore clipboard access errors, but log to analytics to monitor
      AnalyticsService.logError(
        errorType: 'ReaderProvider_checkClipboardAndTranslate',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// Manually trigger translation for custom/copied text
  Future<void> translateText(String text) async {
    if (text.trim().isEmpty) return;

    _isTranslating = true;
    _translationError = null;
    _originalText = text;
    notifyListeners();

    try {
      AnalyticsService.logTranslation(
        textLength: text.length,
        targetLang: _targetLanguage,
      );
      _translatedText = await TranslationService.translate(text, _targetLanguage);
    } catch (e, stack) {
      _translationError =
          'Gagal menerjemahkan: ${e.toString().replaceAll('Exception:', '')}';
      AnalyticsService.logError(
        errorType: 'ReaderProvider_translateText',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// Update the translated text directly (e.g., after manual editing)
  void updateTranslatedText(String newText) {
    _translatedText = newText;
    notifyListeners();
  }

  /// Helper to get the ColorFilter matrix for PDF rendering
  List<double>? get colorFilterMatrix {
    switch (_pdfFilter) {
      case PdfPageFilter.sepia:
        return const [
          0.393,
          0.769,
          0.189,
          0.0,
          0.0,
          0.349,
          0.686,
          0.168,
          0.0,
          0.0,
          0.272,
          0.534,
          0.131,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ];
      case PdfPageFilter.invert:
        return const [
          -1.0,
          0.0,
          0.0,
          0.0,
          255.0,
          0.0,
          -1.0,
          0.0,
          0.0,
          255.0,
          0.0,
          0.0,
          -1.0,
          0.0,
          255.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ];
      case PdfPageFilter.monochrome:
        return const [
          0.2126,
          0.7152,
          0.0722,
          0.0,
          0.0,
          0.2126,
          0.7152,
          0.0722,
          0.0,
          0.0,
          0.2126,
          0.7152,
          0.0722,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ];
      case PdfPageFilter.none:
      default:
        return null;
    }
  }
}
