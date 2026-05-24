import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf_translator/providers/reader_provider.dart';
import 'package:pdf_translator/services/book_history_service.dart';
import 'package:pdf_translator/services/analytics_service.dart';

class PdfViewPane extends StatefulWidget {
  const PdfViewPane({super.key});

  @override
  State<PdfViewPane> createState() => _PdfViewPaneState();
}

class _PdfViewPaneState extends State<PdfViewPane> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isDocumentLoaded = false;
  /// The key of the file that is currently loaded in the viewer.
  /// Used to detect file changes so _isDocumentLoaded can be reset.
  String? _loadedFileKey;
  ReaderProvider? _readerProvider; // kept for safe dispose()
  int _lastLoggedPage = 0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onPageChanged);
    // Register callback so clearTranslation() can clear the PDF text-selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _readerProvider = Provider.of<ReaderProvider>(context, listen: false);
        _readerProvider!.registerClearSelectionCallback(_clearPdfSelection);
      }
    });
  }

  @override
  void dispose() {
    // Unregister the callback before disposing (context is not available here)
    _readerProvider?.unregisterClearSelectionCallback();
    try {
      _pdfViewerController.removeListener(_onPageChanged);
      _pdfViewerController.dispose();
    } catch (e, stack) {
      debugPrint('[PdfViewPane] Error in dispose: $e');
      AnalyticsService.logError(
        errorType: 'PdfViewPane_dispose',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
    }
    super.dispose();
  }

  /// Clears the active text-selection in the PDF viewer.
  void _clearPdfSelection() {
    try {
      _pdfViewerController.clearSelection();
    } catch (e, stack) {
      debugPrint('[PdfViewPane] Error in _clearPdfSelection: $e');
      AnalyticsService.logError(
        errorType: 'PdfViewPane_clearPdfSelection',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
    }
  }

  void _onPageChanged() {
    if (!mounted || !_isDocumentLoaded) {
      return; // Guard to prevent overwriting with page 1 during init or when disposed
    }

    try {
      final provider = _readerProvider ?? Provider.of<ReaderProvider>(context, listen: false);
      final file = provider.selectedFile;
      if (file != null) {
        final key = file.path ?? file.name;
        if (key.isNotEmpty) {
          final currentPage = _pdfViewerController.pageNumber;
          if (currentPage > 0) {
            BookHistoryService.saveLastReadPage(key, currentPage);
            if (currentPage != _lastLoggedPage) {
              _lastLoggedPage = currentPage;
              AnalyticsService.logPageReadProgress(
                bookKey: key,
                pageNumber: currentPage,
              );
            }
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[PdfViewPane] Error in _onPageChanged: $e');
      AnalyticsService.logError(
        errorType: 'PdfViewPane_onPageChanged',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
    }
  }

  /// Shared handler for when a PDF document finishes loading.
  /// Restores the last-read page and then enables the page-change listener.
  void _onDocumentLoaded(String fileKey) {
    try {
      final lastPage = BookHistoryService.getLastReadPage(fileKey);
      
      // Log that a book has been successfully loaded
      final provider = _readerProvider ?? Provider.of<ReaderProvider>(context, listen: false);
      final file = provider.selectedFile;
      if (file != null) {
        AnalyticsService.logBookOpened(file.name, file.size);
      }

      if (lastPage > 1) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            try {
              _pdfViewerController.jumpToPage(lastPage);
              // Delay enabling listener to let the jump complete first
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    _isDocumentLoaded = true;
                  });
                }
              });
            } catch (e, stack) {
              debugPrint('[PdfViewPane] Error jumping to page $lastPage: $e');
              AnalyticsService.logError(
                errorType: 'PdfViewPane_jumpToPage',
                errorMessage: e.toString(),
                stackTrace: stack.toString(),
              );
              setState(() {
                _isDocumentLoaded = true;
              });
            }
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isDocumentLoaded = true;
          });
        }
      }
    } catch (e, stack) {
      debugPrint('[PdfViewPane] Error in _onDocumentLoaded: $e');
      AnalyticsService.logError(
        errorType: 'PdfViewPane_onDocumentLoaded',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
      setState(() {
        _isDocumentLoaded = true;
      });
    }
  }

  void _onTextSelectionChanged(
      PdfTextSelectionChangedDetails details, ReaderProvider provider) {
    try {
      final selectedText = details.selectedText;
      
      // Defer updating the provider state to the next frame to avoid modifying
      // state during the layout/paint/build cycles when the widget tree is locked.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          if (selectedText != null && selectedText.trim().isNotEmpty) {
            provider.setSelectedText(selectedText);
          } else {
            provider.clearSelectedText();
          }
        } catch (e, stack) {
          debugPrint('[PdfViewPane] Error in deferred selection callback: $e');
          AnalyticsService.logError(
            errorType: 'PdfViewPane_deferredTextSelectionChanged',
            errorMessage: e.toString(),
            stackTrace: stack.toString(),
          );
        }
      });
    } catch (e, stack) {
      debugPrint('[PdfViewPane] Error in _onTextSelectionChanged: $e');
      AnalyticsService.logError(
        errorType: 'PdfViewPane_onTextSelectionChanged',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    final file = provider.selectedFile;

    if (file == null) {
      return const Center(child: Text('Tidak ada file terpilih.'));
    }

    // Detect file change and reset loaded flag so _onPageChanged is suppressed
    // during the transition, preventing stale history writes.
    final fileKey = file.path ?? file.name;
    if (fileKey != _loadedFileKey) {
      _isDocumentLoaded = false;
      _loadedFileKey = fileKey;
      _lastLoggedPage = 0;
    }

    final matrix = provider.colorFilterMatrix;
    final interactionMode = provider.interactionMode == ReaderInteractionMode.selection
        ? PdfInteractionMode.selection
        : PdfInteractionMode.pan;

    final scrollDirection = provider.isBookMode
        ? PdfScrollDirection.horizontal
        : PdfScrollDirection.vertical;
    final pageLayoutMode = provider.isBookMode
        ? PdfPageLayoutMode.single
        : PdfPageLayoutMode.continuous;

    // ValueKey forces Flutter to fully tear down and rebuild SfPdfViewer when
    // the file changes. Without this, Flutter reuses the widget and Syncfusion
    // tries to load a new PDF into an already-active controller, which can
    // cause a deadlock / ANR on Android.
    final viewerKey = ValueKey(fileKey);

    Widget viewer;
    if (kIsWeb || file.bytes != null) {
      viewer = SfPdfViewer.memory(
        key: viewerKey,
        file.bytes!,
        controller: _pdfViewerController,
        interactionMode: interactionMode,
        scrollDirection: scrollDirection,
        pageLayoutMode: pageLayoutMode,
        canShowTextSelectionMenu: false,
        canShowScrollHead: !provider.isBookMode,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (_) => _onDocumentLoaded(fileKey),
        onTextSelectionChanged: (details) =>
            _onTextSelectionChanged(details, provider),
      );
    } else {
      viewer = SfPdfViewer.file(
        key: viewerKey,
        io.File(file.path!),
        controller: _pdfViewerController,
        interactionMode: interactionMode,
        scrollDirection: scrollDirection,
        pageLayoutMode: pageLayoutMode,
        canShowTextSelectionMenu: false,
        canShowScrollHead: !provider.isBookMode,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (_) => _onDocumentLoaded(fileKey),
        onTextSelectionChanged: (details) =>
            _onTextSelectionChanged(details, provider),
      );
    }

    // Wrap the viewer in a ColorFiltered container if a matrix filter is active
    return ClipRect(
      child: matrix != null
          ? ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: viewer)
          : viewer,
    );
  }
}
