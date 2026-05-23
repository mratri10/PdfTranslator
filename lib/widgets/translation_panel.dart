import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf_translator/providers/reader_provider.dart';

class TranslationPanel extends StatefulWidget {
  const TranslationPanel({super.key});

  @override
  State<TranslationPanel> createState() => _TranslationPanelState();
}

class _TranslationPanelState extends State<TranslationPanel> {
  bool _isExpanded = false;

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Terjemahan disalin ke clipboard!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    final theme = provider.currentTheme;

    // Determine panel height
    final double panelHeight = _isExpanded ? 240.0 : 120.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: panelHeight,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDark ? 0.4 : 0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle and options bar
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  // Minimal handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.textColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Language Selector
                      Row(
                        children: [
                          Icon(
                            Icons.g_translate_rounded,
                            size: 16,
                            color: theme.textColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          DropdownButton<String>(
                            value: provider.targetLanguage,
                            dropdownColor: theme.surfaceColor,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: theme.textColor.withOpacity(0.7),
                            ),
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            items: provider.supportedLanguages.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                provider.changeTargetLanguage(val);
                              }
                            },
                          ),
                        ],
                      ),
                      // Font Resizer & Expand Toggle
                      Row(
                        children: [
                          // Font size buttons
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: theme.textColor.withOpacity(0.7),
                            onPressed: provider.translationFontSize > 12.0
                                ? () => provider.changeFontSize(provider.translationFontSize - 2.0)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              '${provider.translationFontSize.toInt()}px',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textColor.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: theme.textColor.withOpacity(0.7),
                            onPressed: provider.translationFontSize < 28.0
                                ? () => provider.changeFontSize(provider.translationFontSize + 2.0)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          // Expand/Collapse icon
                          Icon(
                            _isExpanded 
                                ? Icons.keyboard_arrow_down_rounded 
                                : Icons.keyboard_arrow_up_rounded,
                            color: theme.textColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.textColor.withOpacity(0.15),
          ),
          // Content Area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Paste Button (Left)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: provider.isTranslating ? null : () => provider.pasteAndTranslate(),
                    child: Container(
                      width: 90,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: theme.textColor.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: provider.isTranslating
                                  ? theme.textColor.withOpacity(0.05)
                                  : theme.accentColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.content_paste_rounded,
                              color: provider.isTranslating
                                  ? theme.textColor.withOpacity(0.4)
                                  : theme.accentColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PASTE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: provider.isTranslating
                                  ? theme.textColor.withOpacity(0.4)
                                  : theme.accentColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Text Translation Viewer (Right)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: theme.backgroundColor.withOpacity(0.3),
                    child: Stack(
                      children: [
                        // Core Scrollable Text View
                        Positioned.fill(
                          child: SingleChildScrollView(
                            child: _buildTranslationContent(provider, theme),
                          ),
                        ),
                        // Quick Action Floating Buttons (Copy/Clear)
                        if (provider.translatedText.isNotEmpty && !provider.isTranslating)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Row(
                              children: [
                                // Copy Button
                                Material(
                                  color: theme.surfaceColor,
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _copyToClipboard(context, provider.translatedText),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 14,
                                        color: theme.accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationContent(ReaderProvider provider, var theme) {
    if (provider.isTranslating) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Menerjemahkan...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.translationError != null) {
      return Text(
        provider.translationError!,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 13,
        ),
      );
    }

    if (provider.translatedText.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'Hasil terjemahan akan muncul di sini...\n\nPetunjuk: Salin teks dari PDF di atas lalu ketuk tombol PASTE, atau cukup seleksi teks pada dokumen untuk menerjemahkan secara instan.',
          style: TextStyle(
            color: theme.textColor.withOpacity(0.4),
            fontSize: 13,
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original text header
          if (_isExpanded && provider.originalText.isNotEmpty) ...[
            Text(
              'Teks Asli:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: theme.textColor.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              provider.originalText,
              style: TextStyle(
                fontSize: provider.translationFontSize - 2,
                color: theme.textColor.withOpacity(0.65),
                height: 1.4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: theme.textColor.withOpacity(0.1),
              ),
            ),
          ],
          // Translated Text
          Text(
            provider.translatedText,
            style: TextStyle(
              fontSize: provider.translationFontSize,
              color: theme.textColor,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20), // spacer for floating buttons
        ],
      ),
    );
  }
}
