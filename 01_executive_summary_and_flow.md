# PRODUCT REQUIREMENT DOCUMENT (PRD)
## Project Name: PDF Reader & Translator App
**Platform Support:** Android, iOS, Web (PWA)  
**Framework:** Flutter  
**Version:** 1.0.0  
**Date:** May 23, 2026  

---

## 1. Executive Summary & Core Concept
Aplikasi ini dirancang sebagai PDF Reader minimalis yang berfokus pada fungsionalitas membaca dokumen sekaligus menerjemahkan kata atau kalimat asing secara instan menggunakan mekanisme **Copy-Paste** internal.

### Core Workflow:
1. **Landing State:** Tampilan awal bersih (clean screen) hanya dengan satu tombol/ikon utama untuk mengunggah atau memilih file PDF.
2. **Reading State:** File PDF dirender secara penuh. Pengguna dapat membaca dokumen dengan kontrol *scroll* dan *zoom*.
3. **Selection & Copy:** Pengguna memanfaatkan fitur seleksi teks bawaan sistem (*click & drag*) untuk menyalin (Copy) kata/kalimat yang tidak dimengerti.
4. **Translation Bar:** Di bagian bawah layar (*persistent bottom bar*), terdapat tombol **Paste**. Ketika diklik, teks dari clipboard akan ditempelkan, diterjemahkan secara otomatis, dan hasilnya langsung ditampilkan pada area **Text View** kosong yang berada di sisi kanan tombol Paste.

---