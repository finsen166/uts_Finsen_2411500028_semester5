# Kas Kecil
# UTS Pemrograman Multi Platform

## Deskripsi Aplikasi

**Kas Kecil** adalah aplikasi manajemen keuangan pribadi sederhana yang dibangun menggunakan Flutter dan Firebase sebagai proyek UTS Pemrograman Multi Platform. Aplikasi ini memungkinkan pengguna untuk mencatat pemasukan dan pengeluaran, melihat ringkasan keuangan, serta melihat katalog produk melalui REST API.

---

## Fitur Utama

- **Autentikasi** — Register dan login menggunakan email & password melalui Firebase Authentication.
- **Dashboard Kas Kecil** — Menampilkan saldo bersih, total pemasukan, total pengeluaran, dan jumlah transaksi.
- **CRUD Transaksi** — Tambah, lihat, edit, dan hapus transaksi (pemasukan/pengeluaran).
- **Filter & Pencarian** — Saring transaksi berdasarkan jenis dan kata kunci.
- **Format Rupiah** — Nominal ditampilkan dalam format mata uang Rupiah Indonesia.
- **Konfirmasi Hapus** — Dialog konfirmasi sebelum transaksi dihapus.
- **Produk API** — Menampilkan daftar produk dari DummyJSON API menggunakan Dio.
- **Detail Produk** — Halaman detail produk dengan galeri gambar, rating, deskripsi, dan informasi lengkap.
- **Responsif** — Layout menyesuaikan lebar layar browser (mobile, tablet, desktop).

---

## Teknologi yang Digunakan

| Teknologi | Fungsi |
|---|---|
| Flutter & Dart | Framework utama |
| Firebase Core | Inisialisasi Firebase |
| Firebase Authentication | Login & register |
| Cloud Firestore | Database transaksi |
| Provider | State management |
| Dio | HTTP client untuk REST API |
| intl | Format tanggal dan mata uang |
| cached_network_image | Cache gambar produk |
| shimmer | Loading placeholder |

---

## Struktur Folder

```
lib/
├── main.dart                    # Entry point aplikasi
├── firebase_options.dart        # Konfigurasi Firebase (generate via FlutterFire CLI)
├── models/
│   ├── transaction_model.dart   # Model data transaksi
│   └── product_model.dart       # Model data produk API
├── services/
│   ├── firestore_service.dart   # Operasi CRUD Firestore
│   └── api_service.dart         # Request ke DummyJSON API
├── providers/
│   ├── auth_provider.dart       # State autentikasi
│   ├── transaction_provider.dart # State transaksi
│   ├── api_provider.dart        # State produk API
│   └── view_state.dart          # Enum state (loading, loaded, error, dll)
├── screens/
│   ├── auth_gate.dart           # Routing login/home otomatis
│   ├── login_screen.dart        # Halaman login
│   ├── register_screen.dart     # Halaman registrasi
│   ├── home_screen.dart         # Dashboard + navigasi utama
│   ├── transaction_form_screen.dart # Form tambah/edit transaksi
│   ├── api_list_screen.dart     # Daftar produk
│   └── api_detail_screen.dart   # Detail produk
└── widgets/
    ├── loading_widget.dart      # Widget loading indicator
    ├── error_widget.dart        # Widget pesan error
    └── empty_widget.dart        # Widget empty state
```

---

## Cara Menjalankan Project

### Prasyarat

- Flutter SDK (versi 3.0 ke atas) — [Unduh Flutter](https://docs.flutter.dev/get-started/install)
- Dart SDK (sudah disertakan bersama Flutter)
- Google Chrome
- Node.js (untuk FlutterFire CLI)
- Akun Firebase — [console.firebase.google.com](https://console.firebase.google.com)

### 1. Clone Repository

```bash
git clone <url-repository-ini>
cd kas_kecil
```

### 2. Konfigurasi Firebase

> **Penting:** File `firebase_options.dart` harus di-generate menggunakan FlutterFire CLI menggunakan Firebase project milik Anda. Jangan gunakan file dari repository orang lain.

#### a. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

#### b. Login ke Firebase

```bash
firebase login
```

#### c. Generate konfigurasi

Jalankan perintah berikut di direktori project:

```bash
flutterfire configure
```

Ikuti petunjuknya:
- Pilih Firebase project milik Anda
- Centang platform **web** (wajib) dan android/iOS jika diperlukan
- FlutterFire akan men-generate `lib/firebase_options.dart` secara otomatis

### 3. Aktifkan Email/Password Authentication

1. Buka [Firebase Console](https://console.firebase.google.com) → pilih project Anda
2. Klik **Authentication** → tab **Sign-in method**
3. Aktifkan **Email/Password**
4. Klik **Save**

### 4. Buat Firestore Database

1. Di Firebase Console → klik **Firestore Database**
2. Klik **Create database**
3. Pilih lokasi (disarankan: **asia-southeast1 (Singapore)**)
4. Pilih **Start in test mode** sementara (atau production mode jika sudah siap)
5. Klik **Enable**

### 5. Terapkan Firestore Security Rules

> **Jangan** biarkan database terbuka untuk umum. Salin isi `firestore.rules.example` ke Firestore Security Rules.

1. Di Firebase Console → **Firestore Database** → tab **Rules**
2. Salin isi file [`firestore.rules.example`](firestore.rules.example) ke editor rules
3. Klik **Publish**

### 6. Install Dependencies

```bash
flutter pub get
```

### 7. Jalankan Aplikasi di Chrome

```bash
flutter run -d chrome
```

Atau untuk web build production:

```bash
flutter build web
```

---

## Pembagian Peran Anggota Kelompok

> Sesuaikan dengan kontribusi nyata anggota kelompok Anda.

| No | Nama | NIM | Peran / Kontribusi |
|---|---|---|---|
| 1 | *(Nama Anggota 1)* | *(NIM)* | *(Contoh: Setup Firebase, AuthProvider, Login & Register Screen)* |
| 2 | *(Nama Anggota 2)* | *(NIM)* | *(Contoh: TransactionProvider, CRUD Firestore, HomeScreen)* |
| 3 | *(Nama Anggota 3)* | *(NIM)* | *(Contoh: ApiService, ApiProvider, ApiListScreen, ApiDetailScreen)* |

---

## Screenshot Aplikasi

> *(Tambahkan screenshot setelah aplikasi berjalan)*

| Halaman Login | Dashboard | Form Transaksi | Daftar Produk |
|---|---|---|---|
| *(screenshot)* | *(screenshot)* | *(screenshot)* | *(screenshot)* |

---

## Video Presentasi

> *(Isi tautan setelah video tersedia)*

📹 [Link Video Presentasi](#)

---

## Catatan Keamanan

- **Jangan** commit file `google-services.json`, `GoogleService-Info.plist`, atau service account JSON ke repository.
- File `firebase_options.dart` berisi API key publik Firebase yang **aman untuk disertakan** sesuai [kebijakan Firebase](https://firebase.google.com/docs/projects/api-keys), karena akses diproteksi oleh Security Rules dan domain yang diizinkan.
- Pastikan Firestore Security Rules sudah diterapkan sebelum aplikasi digunakan oleh pengguna.
