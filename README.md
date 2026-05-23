# pdf_translator

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

keytool -genkey -v -keystore /Users/atrialfa/documents/myproject/PdfTranslator/atripdf-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias atripdf

**Konfigurasi `key.properties`:**
Buat sebuah file bernama `key.properties` di dalam folder `android/` aplikasi Flutter Anda, lalu masukkan informasi berikut:

```properties
storePassword=260196
keyPassword=260196
keyAlias=atripdf
storeFile=/Users/atrialfa/documents/myproject/PdfTranslator/atripdf-keystore.jks (sesuaikan dengan path file Anda)
```

## Deployment to Firebase Hosting

Aplikasi ini dikonfigurasi untuk dapat dideploy ke Firebase Hosting pada project `atrialfa-1dc01`.

### Langkah-langkah Build & Deploy:

1. **Build Flutter Web:**
   ```bash
   flutter build web --release
   ```

2. **Deploy dengan Firebase CLI (Lokal):**
   ```bash
   npx firebase deploy --only hosting
   ```

Aplikasi web yang dideploy dapat diakses di: [https://atrialfa-1dc01.web.app](https://atrialfa-1dc01.web.app)

