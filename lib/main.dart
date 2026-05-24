import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_translator/models/reader_theme.dart';
import 'package:pdf_translator/providers/reader_provider.dart';
import 'package:pdf_translator/widgets/pdf_view_pane.dart';
import 'package:pdf_translator/widgets/permission_gateway.dart';
import 'package:pdf_translator/widgets/theme_selector.dart';
import 'package:pdf_translator/widgets/translation_panel.dart';
import 'package:pdf_translator/services/book_history_service.dart';
import 'package:pdf_translator/services/book_storage_service.dart';
import 'package:pdf_translator/services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap startup services in try-catch to prevent any startup crash
  try {
    await BookHistoryService.init();
  } catch (e, stack) {
    debugPrint('Failed to initialize BookHistoryService: $e\n$stack');
  }

  try {
    await AnalyticsService.init();
    await AnalyticsService.logAppLaunch();
  } catch (e, stack) {
    debugPrint('Failed to initialize AnalyticsService: $e\n$stack');
  }

  runApp(ChangeNotifierProvider(create: (_) => ReaderProvider(), child: const LingevoApp()));
}

class LingevoApp extends StatelessWidget {
  const LingevoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the current selected theme from the provider
    final readerTheme = Provider.of<ReaderProvider>(context).currentTheme;

    return MaterialApp(
      title: 'Lingevo+',
      debugShowCheckedModeBanner: false,
      theme: readerTheme.toThemeData(),
      // PermissionGateway runs before HomeScreen is shown.
      // On web it is transparent (no-op); on Android it requests storage access.
      home: const PermissionGateway(child: HomeScreen()),
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

    final hasTranslation =
        provider.translatedText.isNotEmpty ||
        provider.isTranslating ||
        provider.translationError != null ||
        provider.selectedText.isNotEmpty;

    // Show loading overlay when file picker or processing is active
    return PopScope(
      canPop: file == null,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (hasTranslation) {
          provider.clearTranslation();
        } else if (file != null) {
          provider.clearFile();
        }
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
                color: Colors.black.withAlpha(128),
                child: Center(
                  child: Card(
                    color: theme.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
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
    BuildContext context,
    ReaderProvider provider,
    ReaderTheme theme,
  ) {
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
          Icon(Icons.picture_as_pdf_rounded, color: theme.accentColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    BuildContext context,
    ReaderProvider provider,
    ReaderTheme theme,
  ) {
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
                      color: theme.accentColor.withAlpha(38),
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
                'LINGEVO+',
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
                  color: theme.textColor.withAlpha(166),
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
                      color: theme.accentColor.withAlpha(102),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(theme.isDark ? 51 : 13),
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
                                color: theme.textColor.withAlpha(128),
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
                    color: Colors.redAccent.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withAlpha(77)),
                  ),
                  child: Text(
                    provider.fileError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                      color: theme.textColor.withAlpha(31),
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
                                  color: theme.textColor.withAlpha(217),
                                ),
                              ),
                            ),
                            const ThemeSelector(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(color: theme.textColor.withAlpha(26), height: 1),
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
                                  color: theme.textColor.withAlpha(217),
                                ),
                              ),
                            ),
                            DropdownButton<String>(
                              value: provider.targetLanguage,
                              dropdownColor: theme.surfaceColor,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: theme.textColor.withAlpha(179),
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
                        Divider(color: theme.textColor.withAlpha(26), height: 1),
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
                                  color: theme.textColor.withAlpha(217),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: theme.textColor.withAlpha(179),
                                  onPressed: provider.translationFontSize > 8.0
                                      ? () => provider.changeFontSize(
                                          provider.translationFontSize - 2.0,
                                        )
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
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: theme.textColor.withAlpha(179),
                                  onPressed: provider.translationFontSize < 16.0
                                      ? () => provider.changeFontSize(
                                          provider.translationFontSize + 2.0,
                                        )
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
    BuildContext context,
    ReaderProvider provider,
    ReaderTheme theme,
  ) {
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          // Main PDF view pane
          const Positioned.fill(child: PdfViewPane()),
          // Persistent translation bottom bar
          const Align(
            alignment: Alignment.bottomCenter,
            child: TranslationPanel(),
          ),
        ],
      ),
    );
  }

  // --- Local Book Shelf Widget ---
  Widget _buildLocalBookShelf(
    BuildContext context,
    ReaderProvider provider,
    ReaderTheme theme,
  ) {
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
                  color: theme.textColor.withAlpha(140),
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
                side: BorderSide(color: theme.textColor.withAlpha(31)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 36,
                      color: theme.textColor.withAlpha(128),
                    ),
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
                        color: theme.textColor.withAlpha(153),
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
                side: BorderSide(color: theme.textColor.withAlpha(31)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 36,
                      color: theme.textColor.withAlpha(128),
                    ),
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
                            color: theme.textColor.withAlpha(153),
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
                        border: Border.all(color: theme.textColor.withAlpha(20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.redAccent,
                            size: 24,
                          ),
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
                                  lastPage > 1
                                      ? 'Terakhir dibaca: Hal $lastPage'
                                      : 'Belum pernah dibaca',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textColor.withAlpha(128),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.textColor.withAlpha(102),
                          ),
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
