import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pdf_translator/main.dart';
import 'package:pdf_translator/providers/reader_provider.dart';

void main() {
  testWidgets('Lingevo+ smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ReaderProvider(),
        child: const LingevoApp(),
      ),
    );

    // Wait for the async permission checks in PermissionGateway to resolve and transition
    await tester.pump(const Duration(seconds: 1));

    // Verify that the landing screen components exist
    expect(find.text('LINGEVO+'), findsOneWidget);
    expect(find.text('Pilih File PDF'), findsOneWidget);
  });
}
