## 4. Non-Functional Requirements (NFR)
* **Performa Rendering:** File PDF dengan ukuran hingga 50MB harus dapat dimuat di perangkat mobile kelas menengah dalam waktu < 3 detik (menggunakan teknik *lazy load per page*).
* **UI/UX Responsiveness:** Bottom Translation Bar tidak boleh menutupi teks PDF paling bawah jika dokumen di-scroll penuh (*padding bottom adjustment*).
* **PWA Compatibility:** Web build harus menyertakan file `manifest.json` dan ikon aplikasi yang valid agar memenuhi kriteria "Installable" sebagai aplikasi PWA di browser Chrome/Safari.
* **Keamanan Data:** Aplikasi tidak menyimpan file PDF di cloud server eksternal; pemrosesan dokumen sepenuhnya terjadi secara lokal di sisi klien (*on-device data privacy*).

---

## 5. UI Layout Blueprint

```
+------------------------------------------+
|                 [ Nama File ]            |
+------------------------------------------+
|                                          |
|  Lorem ipsum dolor sit amet, consectetur  |
|  adipiscing elit. [Selected Text: amet]  |
|  sed do eiusmod tempor incididunt ut     |
|  labore et dolore magna aliqua.          |
|                                          |
|                                          |
|                                          |
|                                          |
+------------------------------------------+
| [Paste Icon] | Hasil Terjemahan:         |
|              | "Target arti kata..."     |
+------------------------------------------+
```