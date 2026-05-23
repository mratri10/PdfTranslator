# Aura PDF Translator

A minimalist, high-performance **PDF Reader & Translator** built with Flutter. Aura focuses on a distraction-free, privacy-first workflow to read documents and translate text instantly via clipboard monitoring and inline editing.

---

## 🚀 Key Features

*   **Clean Landing Screen:** A minimalist entry page focused entirely on uploading documents.
*   **High-Fidelity PDF Viewer:** Smooth rendering of PDF files of up to 50MB with continuous vertical scrolling, zoom support, and native text selection.
*   **Clipboard Auto-Translation:** Copy words/sentences directly from the PDF, and see automatic translations instantly in the persistent bottom panel.
*   **Inline Editing:** Tweak translated sentences on-the-fly using the built-in edit capability, and confirm to update the active translation view.
*   **Privacy-First Architecture:** PDF processing and rendering happen entirely on-device; no documents are uploaded to external cloud servers.
*   **Bilingual Reading Themes:** Optimized reading modes including Sepia, Solarized Dark, Charcoal Night, and Light theme to minimize eye strain.

---

## 🛠️ Tech Stack & Key Abstractions

*   **Framework:** Flutter 3.35.0 (Dart 3.9.0)
*   **PDF Core Viewer:** `syncfusion_flutter_pdfviewer`
*   **File Selection:** `file_picker`
*   **State Management:** `provider`
*   **Translation Engine:** `translator` (Google Translate Scraping Engine)

---

## 💻 Local Development

### Prerequisites
*   Flutter SDK (v3.35.0+)
*   Node.js (for deploying to Firebase)

### Setup & Launch
1.  Clone this repository and navigate to the project directory.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the development application:
    ```bash
    # Run on default connected device
    flutter run

    # Run for Web
    flutter run -d chrome
    ```

---

## 📦 Deployment Guide

### 1. Web Deployment (Firebase Hosting)

The web target is configured to run as a Progressive Web App (PWA) and is deployed to Firebase Hosting.

#### Step-by-Step Web Build & Deploy:
1.  **Build the release package:**
    This command compiles the app to optimized JavaScript and asset bundles under the `build/web` directory:
    ```bash
    flutter build web --release
    ```
2.  **Deploy using Firebase CLI:**
    Using the local installation of `firebase-tools` specified in `package.json`, deploy to the hosting target:
    ```bash
    npx firebase deploy --only hosting
    ```
    
*The app is currently deployed live at: [https://atrialfa-1dc01.web.app](https://atrialfa-1dc01.web.app)*

---

### 2. Android Deployment (Release & Signing)

#### Setup Signing Keystore:
Generate a secure upload keystore with Java's keytool utility:
```bash
keytool -genkey -v -keystore /Users/atrialfa/documents/myproject/PdfTranslator/atripdf-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias atripdf
```

#### Configure `key.properties`:
Create a file named `key.properties` inside the `android/` directory and populate it with details of the keystore:
```properties
storePassword=260196
keyPassword=260196
keyAlias=atripdf
storeFile=/Users/atrialfa/documents/myproject/PdfTranslator/atripdf-keystore.jks
```

#### Compile release bundles:
*   **Build an APK (Direct Install):**
    ```bash
    flutter build apk --release
    ```
*   **Build an Android App Bundle (AAB for Google Play Console):**
    ```bash
    flutter build appbundle --release
    ```
