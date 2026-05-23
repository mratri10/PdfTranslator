import 'package:hive_flutter/hive_flutter.dart';

class BookHistoryService {
  static const String _boxName = 'book_history_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static int getLastReadPage(String bookPath) {
    try {
      if (!Hive.isBoxOpen(_boxName)) return 1;
      final box = Hive.box(_boxName);
      return box.get(bookPath, defaultValue: 1) as int;
    } catch (_) {
      return 1;
    }
  }

  static Future<void> saveLastReadPage(String bookPath, int page) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      await box.put(bookPath, page);
    } catch (_) {
      // Ignore write errors
    }
  }
}
