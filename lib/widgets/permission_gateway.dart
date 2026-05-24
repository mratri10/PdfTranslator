import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_translator/providers/reader_provider.dart';
import 'package:pdf_translator/services/permission_service.dart';
import 'package:pdf_translator/services/book_storage_service.dart';

/// Full-screen splash-style widget shown on first launch (Android only).
/// Requests storage permissions and, once granted, initialises the book shelf
/// before handing off to [child].
class PermissionGateway extends StatefulWidget {
  /// The widget to show after permissions have been handled.
  final Widget child;

  const PermissionGateway({super.key, required this.child});

  @override
  State<PermissionGateway> createState() => _PermissionGatewayState();
}

class _PermissionGatewayState extends State<PermissionGateway>
    with SingleTickerProviderStateMixin {
  /// Lifecycle of the gateway.
  _GatewayState _state = _GatewayState.checking;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _checkPermission();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    // Web / non-Android doesn't need runtime permissions — go straight through.
    if (kIsWeb) {
      setState(() => _state = _GatewayState.granted);
      return;
    }

    final status = await PermissionService.checkStoragePermission();
    switch (status) {
      case StoragePermissionStatus.granted:
      case StoragePermissionStatus.notRequired:
        await _onGranted();
        break;
      case StoragePermissionStatus.permanentlyDenied:
        if (mounted) setState(() => _state = _GatewayState.permanentlyDenied);
        break;
      case StoragePermissionStatus.denied:
        // Show the request screen on first launch
        if (mounted) setState(() => _state = _GatewayState.needsRequest);
        break;
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _state = _GatewayState.requesting);
    final status = await PermissionService.requestStoragePermission();
    switch (status) {
      case StoragePermissionStatus.granted:
      case StoragePermissionStatus.notRequired:
        await _onGranted();
        break;
      case StoragePermissionStatus.permanentlyDenied:
        if (mounted) setState(() => _state = _GatewayState.permanentlyDenied);
        break;
      case StoragePermissionStatus.denied:
        if (mounted) setState(() => _state = _GatewayState.denied);
        break;
    }
  }

  /// Called when storage permission has been confirmed.
  /// Creates the book folder (if missing) and refreshes the book list.
  Future<void> _onGranted() async {
    final folderExists = await BookStorageService.checkFolderExists();
    if (!folderExists) {
      await BookStorageService.createBookFolder();
    }
    // Refresh the provider's book list so the shelf is ready immediately.
    if (mounted) {
      await Provider.of<ReaderProvider>(context, listen: false)
          .refreshLocalBooks();
      setState(() => _state = _GatewayState.granted);
    }
  }

  // ─────────────────────────────────────── build ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Once granted, show the real app immediately.
    if (_state == _GatewayState.granted) return widget.child;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── App icon ──
                  _buildIconBadge(colorScheme),
                  const SizedBox(height: 28),

                  // ── Title ──
                  Text(
                    'Izin Diperlukan',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aura membutuhkan akses penyimpanan untuk:\n',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withAlpha(166),
                      height: 1.4,
                    ),
                  ),

                  // ── Permission items ──
                  _buildPermissionItem(
                    icon: Icons.folder_open_rounded,
                    color: colorScheme.primary,
                    title: 'Baca Buku dari Penyimpanan',
                    subtitle:
                        'Akses folder book-pdf untuk menampilkan koleksi buku PDF Anda.',
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionItem(
                    icon: Icons.bookmark_rounded,
                    color: Colors.orangeAccent,
                    title: 'Simpan Progress Membaca',
                    subtitle:
                        'Halaman terakhir dibaca disimpan otomatis agar Anda dapat melanjutkan kapan saja.',
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 32),

                  // ── Action button ──
                  _buildActionButton(colorScheme),

                  // ── Skip note ──
                  if (_state == _GatewayState.needsRequest ||
                      _state == _GatewayState.denied) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          setState(() => _state = _GatewayState.granted),
                      child: Text(
                        'Lewati untuk sekarang',
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(115),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(64),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.picture_as_pdf_rounded,
        size: 64,
        color: cs.primary,
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(38),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(153),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ColorScheme cs) {
    switch (_state) {
      case _GatewayState.checking:
      case _GatewayState.requesting:
        return Column(
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 12),
            Text(
              'Memeriksa izin...',
              style: TextStyle(
                color: cs.onSurface.withAlpha(140),
                fontSize: 13,
              ),
            ),
          ],
        );

      case _GatewayState.needsRequest:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text(
              'Berikan Izin Akses',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onPressed: _requestPermission,
          ),
        );

      case _GatewayState.denied:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withAlpha(31),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withAlpha(89)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Izin ditolak. Beberapa fitur tidak akan berfungsi.',
                      style: TextStyle(
                        color: Colors.orangeAccent.shade700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _requestPermission,
              ),
            ),
          ],
        );

      case _GatewayState.permanentlyDenied:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withAlpha(64)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded,
                      color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Izin ditolak secara permanen. Aktifkan secara manual melalui Pengaturan.',
                      style: TextStyle(
                        color: Colors.redAccent.shade200,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.settings_rounded),
                label: const Text(
                  'Buka Pengaturan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () async {
                  await PermissionService.openSettings();
                  // Re-check after returning from Settings
                  if (mounted) _checkPermission();
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _state = _GatewayState.granted),
              child: Text(
                'Lanjutkan tanpa izin',
                style: TextStyle(
                  color: cs.onSurface.withAlpha(115),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );

      case _GatewayState.granted:
        return const SizedBox.shrink();
    }
  }
}

enum _GatewayState {
  checking,
  needsRequest,
  requesting,
  denied,
  permanentlyDenied,
  granted,
}
