## 3. Detailed Feature Requirements (FR)
### FR-01: File Selection Layer (Initial Screen)
* **Deskripsi:** Layar pertama yang dilihat pengguna saat membuka aplikasi. Tidak ada distrasi visual, hanya berfokus pada aksi mengunggah dokumen.
* **Komponen UI:** Ikon besar di tengah layar bertema dokumen/upload dengan label "Pilih File PDF".
* **Fungsionalitas:** * Memicu file picker sistem.
    * Menerapkan filter ekstensi file khusus `.pdf`.
    * Validasi file rusak/corrupted dengan indikator error yang informatif.

### FR-02: PDF Core Rendering Engine
* **Deskripsi:** Viewer utama dokumen PDF setelah file berhasil dipilih.
* **Fungsionalitas:**
    * Mendukung *continuous vertical scrolling* dan *horizontal swipe* (opsional via konfigurasi).
    * Mendukung *pinch-to-zoom* untuk perangkat mobile dan *mouse-wheel zoom* untuk Web.
    * Mengaktifkan *native text selection overlay* secara otomatis agar pengguna bisa menahan jari/kursor untuk memblok kata/kalimat dan menekan opsi "Copy" dari *system context menu*.

### FR-03: Floating / Persistent Translation Toolbar
* **Deskripsi:** Komponen bar statis yang berada di area bawah layar (bottom area) yang menumpuk di atas PDF Viewer (atau memotong *safe area* bawah).
* **Komponen UI & Tata Letak:**
    * **Sisi Kiri:** Tombol/Ikon "Paste" (Icon berbentuk clipboard atau tombol teks dengan aksen warna kontras).
    * **Sisi Kanan:** Area *Text View* kosong dengan latar belakang semi-transparan atau warna solid netral. Menggunakan *placeholder* teks seperti *"Hasil terjemahan akan muncul di sini..."*.
* **Logika Interaksi:**
    1. Pengguna memblok teks di PDF -> Memilih **Copy** dari menu bawaan HP/Browser.
    2. Pengguna menekan ikon **Paste** di bottom bar.
    3. Aplikasi mengambil data terbaru dari string clipboard sistem (`ClipboardData`).
    4. Aplikasi mendeteksi bahasa sumber otomatis (Auto-detect) dan mengirim request ke API penerjemah menuju bahasa target (default: Bahasa Indonesia).
    5. Selama proses fetch API, area Text View kanan menampilkan status *loading indicator* kecil atau animasi berkedip.
    6. Hasil terjemahan ditampilkan di area *Text View* tersebut secara instan.

---