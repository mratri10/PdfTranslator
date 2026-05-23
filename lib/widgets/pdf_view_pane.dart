import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf_translator/providers/reader_provider.dart';
import 'package:pdf_translator/services/book_history_service.dart';

class PdfViewPane extends StatefulWidget {
  const PdfViewPane({super.key});

  @override
  State<PdfViewPane> createState() => _PdfViewPaneState();
}

class _PdfViewPaneState extends State<PdfViewPane> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isDocumentLoaded = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pdfViewerController.removeListener(_onPageChanged);
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (!_isDocumentLoaded)
      return; // Guard to prevent overwriting with page 1 during init

    final provider = Provider.of<ReaderProvider>(context, listen: false);
    final file = provider.selectedFile;
    if (file != null) {
      final key = file.path ?? file.name;
      if (key.isNotEmpty) {
        final currentPage = _pdfViewerController.pageNumber;
        if (currentPage > 0) {
          BookHistoryService.saveLastReadPage(key, currentPage);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    final file = provider.selectedFile;

    if (file == null) {
      return const Center(child: Text('Tidak ada file terpilih.'));
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

    Widget viewer;
    if (kIsWeb || file.bytes != null) {
      viewer = SfPdfViewer.memory(
        file.bytes!,
        controller: _pdfViewerController,
        interactionMode: interactionMode,
        scrollDirection: scrollDirection,
        pageLayoutMode: pageLayoutMode,
        canShowTextSelectionMenu: false, // Disable native context menu
        canShowScrollHead: !provider.isBookMode,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          final key = file.path ?? file.name;
          if (key.isNotEmpty) {
            final lastPage = BookHistoryService.getLastReadPage(key);
            if (lastPage > 1) {
              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted) {
                  _pdfViewerController.jumpToPage(lastPage);
                  // Delay turning on the listener slightly to ensure jump finishes
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        _isDocumentLoaded = true;
                      });
                    }
                  });
                }
              });
            } else {
              setState(() {
                _isDocumentLoaded = true;
              });
            }
          } else {
            setState(() {
              _isDocumentLoaded = true;
            });
          }
        },
        onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
          final selectedText = details.selectedText;
          if (selectedText != null && selectedText.trim().isNotEmpty) {
            provider.translateText(selectedText);
          }
        },
      );
    } else {
      viewer = SfPdfViewer.file(
        io.File(file.path!),
        controller: _pdfViewerController,
        interactionMode: interactionMode,
        scrollDirection: scrollDirection,
        pageLayoutMode: pageLayoutMode,
        canShowTextSelectionMenu: false, // Disable native context menu
        canShowScrollHead: !provider.isBookMode,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          final key = file.path ?? file.name;
          if (key.isNotEmpty) {
            final lastPage = BookHistoryService.getLastReadPage(key);
            if (lastPage > 1) {
              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted) {
                  _pdfViewerController.jumpToPage(lastPage);
                  // Delay turning on the listener slightly to ensure jump finishes
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        _isDocumentLoaded = true;
                      });
                    }
                  });
                }
              });
            } else {
              setState(() {
                _isDocumentLoaded = true;
              });
            }
          } else {
            setState(() {
              _isDocumentLoaded = true;
            });
          }
        },
        onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
          final selectedText = details.selectedText;
          if (selectedText != null && selectedText.trim().isNotEmpty) {
            provider.translateText(selectedText);
          }
        },
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
