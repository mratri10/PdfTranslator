import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pdf_translator/main.dart';
import 'package:pdf_translator/providers/reader_provider.dart';

void main() {
  testWidgets('Aura PDF Translator smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ReaderProvider(),
        child: const AuraApp(),
      ),
    );

    // Verify that the landing screen components exist
    expect(find.text('AURA TRANSLATOR'), findsOneWidget);
    expect(find.text('Pilih File PDF'), findsOneWidget);
  });
}
