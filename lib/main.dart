import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_translator/models/reader_theme.dart';
import 'package:pdf_translator/providers/reader_provider.dart';
import 'package:pdf_translator/widgets/pdf_view_pane.dart';
import 'package:pdf_translator/widgets/theme_selector.dart';
import 'package:pdf_translator/widgets/translation_panel.dart';
import 'package:pdf_translator/services/book_history_service.dart';
import 'package:pdf_translator/services/book_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BookHistoryService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ReaderProvider(),
      child: const AuraApp(),
    ),
  );
}

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the current selected theme from the provider
    final readerTheme = Provider.of<ReaderProvider>(context).currentTheme;

    return MaterialApp(
      title: 'Aura PDF Translator',
      debugShowCheckedModeBanner: false,
      theme: readerTheme.toThemeData(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final provider = Provider.of<ReaderProvider>(context, listen: false);
      if (provider.selectedFile != null) {
        provider.checkClipboardAndTranslate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    final file = provider.selectedFile;
    final theme = provider.currentTheme;

    // Show loading overlay when file picker or processing is active
    return PopScope(
      canPop: file == null,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        provider.clearFile();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (file != null) {
            provider.checkClipboardAndTranslate();
          }
        },
        child: Stack(
          children: [
            Scaffold(
              appBar: file != null ? _buildReadingAppBar(context, provider, theme) : null,
              body: file == null
                  ? _buildLandingScreen(context, provider, theme)
                  : _buildReadingScreen(context, provider, theme),
            ),
            if (provider.isFileLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Card(
                    color: theme.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Memuat berkas PDF...',
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Reading State AppBar ---
  PreferredSizeWidget _buildReadingAppBar(
      BuildContext context, ReaderProvider provider, ReaderTheme theme) {
    final fileName = provider.selectedFile?.name ?? 'Dokumen';

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Tutup Dokumen',
        onPressed: () {
          provider.clearFile();
        },
      ),
      title: Row(
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            color: theme.accentColor,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            provider.isBookMode ? Icons.auto_stories_rounded : Icons.splitscreen_rounded,
            size: 20,
          ),
          tooltip: provider.isBookMode ? 'Mode Buku (Horizontal)' : 'Mode Vertikal',
          onPressed: () {
            provider.toggleBookMode();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.isBookMode
                      ? 'Mode Buku Aktif (Geser Kanan/Kiri per halaman)'
                      : 'Mode Vertikal Aktif (Scroll ke atas/bawah)',
                ),
                duration: const Duration(milliseconds: 1500),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- Landing Screen (FR-01) ---
  Widget _buildLandingScreen(
      BuildContext context, ReaderProvider provider, ReaderTheme theme) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful icon & app title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.accentColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 72,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AURA TRANSLATOR',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Membaca & menerjemahkan dokumen PDF secara instan tanpa silau mata.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textColor.withOpacity(0.65),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),

              // Upload File Button Card
              GestureDetector(
                onTap: () => provider.pickPdfFile(),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.accentColor.withOpacity(0.4),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(theme.isDark ? 0.2 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => provider.pickPdfFile(),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: theme.accentColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Pilih File PDF',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mendukung format dokumen .pdf',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (provider.fileError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    provider.fileError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              _buildLocalBookShelf(context, provider, theme),

              const SizedBox(height: 48),

              // Configuration Settings Card (Theme, Language, Font Size)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  color: theme.surfaceColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: theme.textColor.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'PENGATURAN MEMBACA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: theme.accentColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 1. Theme selection
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Tema Membaca:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor.withOpacity(0.85),
                                ),
                              ),
                            ),
                            const ThemeSelector(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(color: theme.textColor.withOpacity(0.1), height: 1),
                        const SizedBox(height: 14),

                        // 2. Language selection
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Bahasa Terjemahan:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor.withOpacity(0.85),
                                ),
                              ),
                            ),
                            DropdownButton<String>(
                              value: provider.targetLanguage,
                              dropdownColor: theme.surfaceColor,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: theme.textColor.withOpacity(0.7),
                              ),
                              style: TextStyle(
                                color: theme.accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 14),
                        Divider(color: theme.textColor.withOpacity(0.1), height: 1),
                        const SizedBox(height: 14),

                        // 3. Font Size selection
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ukuran Font:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor.withOpacity(0.85),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: theme.textColor.withOpacity(0.7),
                                  onPressed: provider.translationFontSize > 12.0
                                      ? () => provider.changeFontSize(provider.translationFontSize - 2.0)
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Text(
                                    '${provider.translationFontSize.toInt()}px',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: theme.textColor.withOpacity(0.7),
                                  onPressed: provider.translationFontSize < 28.0
                                      ? () => provider.changeFontSize(provider.translationFontSize + 2.0)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Reading Screen (FR-02 & FR-03) ---
  Widget _buildReadingScreen(
      BuildContext context, ReaderProvider provider, ReaderTheme theme) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Main PDF view pane
          const Expanded(
            child: PdfViewPane(),
          ),
          // Persistent translation bottom bar
          const TranslationPanel(),
        ],
      ),
    );
  }

  // --- Local Book Shelf Widget ---
  Widget _buildLocalBookShelf(BuildContext context, ReaderProvider provider, ReaderTheme theme) {
    if (kIsWeb) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RAK BUKU LOKAL (book-pdf)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor.withOpacity(0.55),
                  letterSpacing: 1.0,
                ),
              ),
              if (provider.bookFolderExists)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: theme.accentColor,
                  tooltip: 'Segarkan Rak Buku',
                  onPressed: () => provider.refreshLocalBooks(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!provider.bookFolderExists)
            Card(
              color: theme.surfaceColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.textColor.withOpacity(0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.folder_open_outlined, size: 36, color: theme.textColor.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Text(
                      'Folder "book-pdf" belum aktif',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Izinkan akses penyimpanan dan buat folder agar Anda dapat menyalin file PDF langsung ke dalamnya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textColor.withOpacity(0.6),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                      label: const Text('Buat Folder book-pdf'),
                      onPressed: () => provider.createBookFolder(),
                    ),
                  ],
                ),
              ),
            )
          else if (provider.localBooks.isEmpty)
            Card(
              color: theme.surfaceColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.textColor.withOpacity(0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.library_books_outlined, size: 36, color: theme.textColor.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Text(
                      'Belum ada buku',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: BookStorageService.getBookFolderPath(),
                      builder: (context, snapshot) {
                        final path = snapshot.data ?? 'book-pdf';
                        return Text(
                          'Silakan salin file PDF Anda ke folder:\n$path\nkemudian segarkan halaman.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textColor.withOpacity(0.6),
                            height: 1.4,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.accentColor,
                        side: BorderSide(color: theme.accentColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Segarkan'),
                      onPressed: () => provider.refreshLocalBooks(),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: provider.localBooks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final file = provider.localBooks[index];
                  final name = file.path.split('/').last;
                  final path = file.path;
                  final lastPage = BookHistoryService.getLastReadPage(path);

                  return InkWell(
                    onTap: () => provider.selectLocalBook(file),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.textColor.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lastPage > 1 ? 'Terakhir dibaca: Hal $lastPage' : 'Belum pernah dibaca',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textColor.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: theme.textColor.withOpacity(0.4)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
