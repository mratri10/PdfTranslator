import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf_translator/providers/reader_provider.dart';

class PdfViewPane extends StatefulWidget {
  const PdfViewPane({super.key});

  @override
  State<PdfViewPane> createState() => _PdfViewPaneState();
}

class _PdfViewPaneState extends State<PdfViewPane> {
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
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

    Widget viewer;
    if (kIsWeb || file.bytes != null) {
      viewer = SfPdfViewer.memory(
        file.bytes!,
        controller: _pdfViewerController,
        interactionMode: interactionMode,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
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
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
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
          ? ColorFiltered(
              colorFilter: ColorFilter.matrix(matrix),
              child: viewer,
            )
          : viewer,
    );
  }
}
