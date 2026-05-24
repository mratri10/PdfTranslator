# Panduan Warna UI/UX & Identitas Aplikasi Lingevo+
**Fokus: Integrasi Brand Logo & Kenyamanan Mata (Eye-Comfort) untuk Pembaca PDF/EPUB**

## 📝 Deskripsi & Visi Aplikasi
**Lingevo+** adalah aplikasi pembaca ebook (PDF & EPUB) cerdas yang dirancang agar pengguna dapat **membaca teks bahasa asing tanpa khawatir tidak mengerti makna dan memperluas kosa kata**. 

Aplikasi ini berfungsi sebagai pembaca ebook sekaligus alat penerjemah instan, yang kemudian berkembang menjadi media latihan bahasa asing interaktif dengan kemampuan menyimpan data atau kalimat yang dikutip langsung dari buku.

---

## 🛑 Aturan Dasar Kenyamanan Mata (Eye-Comfort Rules)
1. **Hindari Hitam Murni pada Putih Murni:** Kontras yang terlalu tinggi menyebabkan silau dan mata cepat lelah (*digital eye strain*).
2. **Hindari Putih Murni pada Hitam Murni:** Teks putih terang pada latar belakang sangat gelap dapat menyebabkan efek *halo* atau teks yang seolah "berbayang".
3. **Gunakan Kontras Lembut (Low Glare):** Teks harus mudah dibaca tetapi tidak menyilaukan.

---

## 🎨 Rekomendasi Palet Warna

### 1. Mode Gelap (The Deep Night)
*Sangat direkomendasikan untuk membaca di malam hari atau ruangan minim cahaya. Mengambil DNA warna gelap dari latar belakang logo Lingevo+.*

| Elemen UI | Warna | HEX Code | Keterangan |
| :--- | :--- | :--- | :--- |
| **Latar Aplikasi (App BG)** | The Deep Blue | `#0C1D2A` | Diambil dari warna tergelap latar belakang logo. Tidak hitam legam. |
| **Latar Sekunder (Menu/Card)**| Graphite Sky | `#1B2B38` | Sedikit lebih terang dari latar utama untuk membedakan area menu. |
| **Teks Utama (EPUB Text)** | Moonstone | `#E0E6ED` | Putih keabu-abuan. Jauh lebih nyaman dari putih murni (`#FFFFFF`). |
| **Aksen Primer (Tombol/Icon)**| Logo Sky Blue | `#4FB5FF` | Biru terang dari elemen sinyal/buku pada logo untuk *call-to-action*. |

---

### 2. Mode Siang (The Nordic Cloud)
*Pengganti mode "Putih" standar. Memberikan kesan modern dan bersih, namun menggunakan abu-abu awan yang sangat lembut untuk menekan pantulan silau layar.*

| Elemen UI | Warna | HEX Code | Keterangan |
| :--- | :--- | :--- | :--- |
| **Latar Aplikasi (App BG)** | Mist White | `#F7F9FC` | Putih abu-abu sejuk (*cool tone*). Mengurangi emisi cahaya putih. |
| **Latar Sekunder (App Bar)** | Logo Deep Blue | `#0066CC` | Biru solid dari bagian bawah buku pada logo untuk *header* aplikasi. |
| **Teks Utama (EPUB Text)** | Deep Charcoal | `#222831` | Abu-abu sangat gelap. Lebih lembut dari hitam murni (`#000000`). |
| **Aksen Primer (Highlight)** | Logo Light Blue| `#4FB5FF` | Warna biru khas Lingevo untuk menandai menu aktif atau *highlight* teks. |

---

### 3. Mode Membaca Optimal (Classic Parchment)
*Mode standar emas untuk aplikasi e-reader. Meniru warna kertas buku fisik (kertas perkamen) yang terbukti paling nyaman untuk membaca berjam-jam.*

| Elemen UI | Warna | HEX Code | Keterangan |
| :--- | :--- | :--- | :--- |
| **Latar Teks (Reading Area)**| Soft Parchment | `#F8F3E9` | Krem hangat/beige. Sangat efektif menetralkan cahaya biru (*blue light*). |
| **Teks Utama (EPUB Text)** | Dark Umber | `#2F2C2A` | Cokelat-abu gelap. Berpadu sangat sempurna dengan latar krem. |
| **Bingkai UI (App Bar/Nav)** | Logo Deep Blue | `#0066CC` | Mempertahankan *branding* Lingevo+ di luar area teks buku. |
| **Aksen (Teks Terpilih)** | Translucent | `rgba(79, 181, 255, 0.2)` | Biru Lingevo+ transparan (opacity 20%) untuk menandai kutipan. |

---

## 💡 Tips Tambahan untuk Developer

* **PDF Dimming Layer:** Berbeda dengan EPUB yang teksnya bisa diubah warna, file PDF biasanya berupa gambar/dokumen statis berlatar putih. Untuk mode gelap, tambahkan fitur **"Dimming"** yaitu lapisan hitam transparan (sekitar `15% - 25% opacity`) di atas render halaman PDF agar warna putihnya tidak menyilaukan.
* **Tipografi (Font):** * Gunakan font *sans-serif* humanis (seperti **Inter** atau **Nunito**) untuk UI/Menu aplikasi.
    * Sediakan opsi font *serif* (seperti **Lora**, **Merriweather**, atau **Garamond**) untuk teks isi buku (EPUB) karena lebih nyaman untuk membaca paragraf panjang.
