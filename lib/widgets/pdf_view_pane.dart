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

    Widget viewer;
    if (kIsWeb || file.bytes != null) {
      viewer = SfPdfViewer.memory(
        file.bytes!,
        controller: _pdfViewerController,
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
    return Column(
      children: [
        // Filter toolbar indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: provider.currentTheme.surfaceColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Halaman PDF:',
                style: TextStyle(
                  fontSize: 12,
                  color: provider.currentTheme.textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: PdfPageFilter.values.map((filter) {
                  final isSelected = provider.pdfFilter == filter;
                  String label = '';
                  switch (filter) {
                    case PdfPageFilter.none:
                      label = 'Normal';
                      break;
                    case PdfPageFilter.sepia:
                      label = 'Sepia';
                      break;
                    case PdfPageFilter.invert:
                      label = 'Gelap (Invert)';
                      break;
                    case PdfPageFilter.monochrome:
                      label = 'B&W';
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? provider.currentTheme.buttonTextColor
                              : provider.currentTheme.textColor,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: provider.currentTheme.accentColor,
                      backgroundColor: provider.currentTheme.backgroundColor,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : provider.currentTheme.textColor.withOpacity(0.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        if (selected) {
                          provider.changePdfFilter(filter);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // PDF Viewer container
        Expanded(
          child: matrix != null
              ? ColorFiltered(
                  colorFilter: ColorFilter.matrix(matrix),
                  child: viewer,
                )
              : viewer,
        ),
      ],
    );
  }
}
