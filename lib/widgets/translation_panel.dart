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
  late TextEditingController _textController;
  bool _isEditing = false;
  String _lastTranslatedText = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Terjemahan disalin ke clipboard!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    final theme = provider.currentTheme;

    // Reset editing state and sync controller when the translation changes from outside
    if (provider.translatedText != _lastTranslatedText) {
      _lastTranslatedText = provider.translatedText;
      _textController.text = provider.translatedText;
      _isEditing = false;
    }

    // Return nothing if there is no active translation, load error, or translation in progress
    final hasContent = provider.translatedText.isNotEmpty || 
                       provider.isTranslating || 
                       provider.translationError != null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: !hasContent
          ? const SizedBox.shrink()
          : Container(
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.isDark ? 0.35 : 0.08),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Small header row with language and action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Target language badge
                        Text(
                          provider.supportedLanguages[provider.targetLanguage]?.toUpperCase() ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: theme.accentColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                        // Quick Action Buttons
                        Row(
                          children: [
                            // Action buttons only if not loading and translation is present
                            if (provider.translatedText.isNotEmpty && !provider.isTranslating) ...[
                              // Copy button
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: theme.textColor.withOpacity(0.55),
                                tooltip: 'Salin Terjemahan',
                                onPressed: () => _copyToClipboard(context, provider.translatedText),
                              ),
                              const SizedBox(width: 14),
                              // Edit / Confirm button
                              IconButton(
                                icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: _isEditing ? theme.accentColor : theme.textColor.withOpacity(0.55),
                                tooltip: _isEditing ? 'Selesai Edit' : 'Edit Terjemahan',
                                onPressed: () {
                                  if (_isEditing) {
                                    final newText = _textController.text;
                                    _lastTranslatedText = newText;
                                    provider.updateTranslatedText(newText);
                                    setState(() {
                                      _isEditing = false;
                                    });
                                  } else {
                                    setState(() {
                                      _textController.text = provider.translatedText;
                                      _isEditing = true;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 14),
                            ],
                            // Close/Dismiss button
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: theme.textColor.withOpacity(0.55),
                              tooltip: 'Tutup',
                              onPressed: () {
                                if (_isEditing) {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                }
                                provider.clearTranslation();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Translation result content
                    _buildTranslationContent(provider, theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTranslationContent(ReaderProvider provider, var theme) {
    if (provider.isTranslating) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Menerjemahkan...',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: theme.textColor.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.translationError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          provider.translationError!,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: TextField(
          controller: _textController,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: TextStyle(
            fontSize: provider.translationFontSize,
            color: theme.textColor,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Edit terjemahan...',
            hintStyle: TextStyle(
              color: theme.textColor.withOpacity(0.35),
            ),
          ),
          autofocus: true,
        ),
      );
    }

    return SelectionArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          provider.translatedText,
          style: TextStyle(
            fontSize: provider.translationFontSize,
            color: theme.textColor,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
