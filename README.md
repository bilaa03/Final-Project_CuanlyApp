# Cuanly — Smart Financial Hub & Expense Intelligence

Proyek ini merupakan Tugas Besar untuk mata kuliah Kecerdasan Buatan (Artificial Intelligence). Aplikasi ini adalah platform pencatatan dan pengelolaan keuangan (pribadi B2C dan corporate B2B) yang terintegrasi dengan teknologi AI, yaitu Optical Character Recognition (OCR) untuk pemindaian struk otomatis dan Retrieval-Augmented Generation (RAG) untuk konsultasi keuangan cerdas.

---

## Identitas Pengembang
* **Nama**: Nabila Zhahra Nursyamsi
* **NIM**: 24110400002
* **Program Studi**: Sistem Teknologi dan Informasi (STI)

---

## Deskripsi Singkat
Pencatatan keuangan sering kali tertunda karena kendala input manual data transaksi yang melelahkan. Cuanly menyelesaikan masalah ini dengan mengotomatisasi input data melalui pemindaian struk (OCR). Selain itu, platform ini menyediakan asisten finansial pintar berbasis RAG yang dapat menjawab pertanyaan pengguna seputar anggaran keuangan atau kebijakan pengembalian dana (reimbursement) berdasarkan basis dokumen referensi internal.

---

## Fitur Utama

### 1. Web Dashboard (React.js + Tailwind CSS)
* **Visualisasi & Analisis**: Menampilkan ringkasan saldo, pemasukan, pengeluaran, sisa anggaran, dan grafik aliran dana.
* **Month Selector Dinamis**: Dropdown bulan di pojok kanan atas yang terhubung ke kalender sistem secara real-time untuk melihat rekaman keuangan bulan lalu, bulan ini, atau bulan depan.
* **Ekspor Laporan Transaksi**: Ekspor seluruh riwayat transaksi ke file `.csv` dengan encoding UTF-8 BOM agar rapi saat dibuka dan diedit di Microsoft Excel atau Google Sheets.
* **Portal Reimbursement B2B**:
  - Formulir pengajuan reimbursement dinas baru.
  - Tabel antrean persetujuan (approval queue) untuk admin menyetujui atau menolak klaim.
  - Unduh berkas laporan anggaran dinas departemen dalam format Excel (.csv) dan Laporan Cetak Teks (.txt).
* **Smart Notification**: Bell notifikasi dengan popover melayang untuk memantau batas anggaran dan tagihan berlangganan.

### 2. Mobile Client (Flutter)
* **Kamera OCR Auto-Detect**: Viewfinder kamera pemindai struk dengan hitung mundur 3 detik yang akan menjepret gambar secara otomatis dan mengunci fokus struk (warna bingkai berubah hijau dengan efek flash putih).
* **Custom Profile Avatar**: Pengguna dapat memilih 4 preset avatar siluet gradasi premium yang tersimpan secara lokal dan dinamis di dalam state.
* **Monitoring & Target Tabungan**: Menampilkan target tabungan aktif beserta progress bar dan notifikasi prediktif mengenai sisa saldo akhir bulan.

---

## Tech Stack
* **Frontend Mobile**: Flutter (Dart)
* **Frontend Web**: React.js & Tailwind CSS
* **Backend Server**: Node.js & Express.js
* **Database**: MySQL dengan Prisma ORM (dilengkapi dengan sistem local JSON fallback agar tetap bisa berjalan tanpa setup database MySQL).
* **AI Engine**: Google Gemini API (`gemini-1.5-flash` / `gemini-2.0-flash`) sebagai LLM utama (dan local fallback simulator jika API Key kosong).

---

## Panduan Menjalankan Proyek

### Langkah 1: Konfigurasi Environment Backend
1. Masuk ke direktori `backend/`.
2. Salin atau ubah nama file `.env.example` menjadi `.env`.
3. Masukkan API Key Anda pada parameter berikut:
   ```env
   AI_PROVIDER=gemini
   GEMINI_API_KEY=MASUKKAN_GEMINI_API_KEY_ANDA_DISINI
   GEMINI_MODEL=gemini-1.5-flash
   ```
   *(Catatan: Jika Anda tidak mengisi API Key, server tetap berjalan menggunakan simulator respons AI lokal agar fungsi demo tetap bekerja).*

### Langkah 2: Menjalankan Server Backend
Pilih salah satu cara berikut untuk menyalakan server Express:

* **Cara A (Windows Background Process - Direkomendasikan)**:
  Buka folder `backend/` dan jalankan berkas **`run_silently.vbs`** dengan klik ganda. Server akan berjalan senyap di latar belakang. Untuk mematikannya kelak, jalankan berkas **`stop_backend.bat`**.
* **Cara B (Windows Command Prompt)**:
  Buka folder `backend/` dan jalankan berkas **`run_backend_background.bat`**. CMD akan terbuka dan menampilkan log server.
* **Cara C (Terminal Manual)**:
  ```bash
  cd backend
  npm install
  npm start
  ```
Server akan aktif di alamat: **`http://localhost:8787`**.

### Langkah 3: Mengakses Web Dashboard
Buka browser dan akses alamat berikut untuk menguji seluruh fitur web:
* **Akses Lokal (PC/Laptop)**: [http://localhost:8787](http://localhost:8787)
* **Akses Jaringan (Perangkat HP)**: [http://172.20.28.137:8787](http://172.20.28.137:8787) *(pastikan berada dalam jaringan Wi-Fi yang sama)*.

### Langkah 4: Menjalankan Flutter Mobile Client
Pastikan HP Anda terhubung lewat USB Debugging atau emulator Android/iOS telah aktif. Masuk ke folder root proyek dan jalankan perintah berikut:
```bash
flutter pub get
flutter run
```

---

## Endpoint API Backend Utama
* `GET /health` : Memeriksa status kesehatan server.
* `GET /financial/state?email=user@email.com` : Mengambil status dompet dan daftar transaksi aktif.
* `POST /financial/transaction` : Menambahkan transaksi baru ke dalam database.
* `POST /rag/query` : Mengirim query pencarian dokumen referensi ke engine RAG.
