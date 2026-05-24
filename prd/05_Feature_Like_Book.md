dependencies:

# Package lama Anda

cupertino_icons: ^1.0.8
file_picker: ^11.0.2
syncfusion_flutter_pdfviewer: ^31.1.19
translator: ^1.0.4+1
provider: ^6.1.5+1

# Tambahan untuk Fitur Baru:

hive_flutter: ^1.1.0 # Database lokal super cepat untuk simpan riwayat baca (halaman terakhir)
path_provider: ^2.1.3 # Mencari path direktori dokumen di perangkat fisik
permission_handler: ^11.3.1 # Meminta izin akses storage (khusus Android/iOS)

2. **Auto Jump ke Halaman Terakhir:** Saat buku diklik kembali oleh pengguna dari daftar riwayat, panggil fungsi `_pdfViewerController.jumpToPage(savedPage)` sesaat setelah dokumen selesai dimuat (`onDocumentLoaded`).

Package syncfusion_flutter_pdfviewer memiliki controller yang sangat lengkap. Anda bisa memanfaatkan PdfViewerController untuk mencatat halaman terakhir yang dibaca pengguna.

\_pdfViewerController.addListener(() {
int currentPage = \_pdfViewerController.pageNumber;
// Simpan currentPage ke database Hive berdasarkan Judul/Path Buku
BookDatabase.saveLastPage(bookPath, currentPage);
});

#### C. Pengalaman Membaca Seperti Buku (Book-like Experience)

Secara bawaan, `syncfusion_flutter_pdfviewer` merender halaman secara vertikal (_continuous scrolling_)[cite: 2]. Untuk mengubahnya agar terasa seperti membaca buku fisik atau _e-reader_ (bisa digeser ke kanan-kiri per halaman):

- Ubah properti `scrollDirection` pada widget menjadi horizontal.
- Aktifkan fitur `pageLayoutMode` menjadi _single page_ (bukan continuous).

```dart
SfPdfViewer.file(
  File(bookPath),
  controller: _pdfViewerController,
  scrollDirection: PdfScrollDirection.horizontal,
  pageLayoutMode: PdfPageLayoutMode.single, // Membaca per halaman seperti buku
)
```
