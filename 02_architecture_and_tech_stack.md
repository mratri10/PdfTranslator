## 2. Platform Architecture & Tech Stack
### 2.1 Operating Systems & Environments
* **Android:** Minimum SDK 21 (Android 5.0), Target SDK 34+.
* **iOS:** Minimum iOS 13.0+, target arsitektur 64-bit.
* **Web (PWA):** Mendukung rendering CanvasKit untuk performa rendering PDF yang presisi, service worker untuk kapabilitas offline PWA, dan responsif terhadap rasio layar desktop/tablet.

### 2.2 Key Flutter Packages
* **PDF Core Viewer:** `syncfusion_flutter_pdfviewer` (Direkomendasikan karena integrasi native text selection yang sangat stabil di Android/iOS/Web).
* **File Picker:** `file_picker` (Mendukung pemilihan file lintas platform termasuk file abstraction di web).
* **Translation Engine:** `translator` (Google Translate API gratis via scraping untuk MVP) atau `http`/`dio` untuk integrasi Cloud Translation API resmi.
* **Clipboard Management:** Menggunakan package bawaan Flutter `import 'package:flutter/services.dart';` (`Clipboard.getData`).
* **State Management:** `flutter_bloc` atau `provider` untuk memisahkan logika translasi dan rendering UI.

---