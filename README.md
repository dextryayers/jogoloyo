# Les Jogoloyo V.01.0 local

Aplikasi les tatap muka. Flutter plus Kotlin. 100 persen lokal. Tanpa database server. Tanpa internet wajib.

Paket Android: id.jogoloyo.les. Min Android 10. Target Android 14.

## Jalankan

```
flutter pub get
dart run build_runner build
flutter run
```

## Verifikasi cepat (wajib sebelum commit)

```
flutter analyze
flutter test
dart run tools/forbid_scan.dart
```

Target: analyze bersih, test 15+ lolos, lint OK tanpa karakter U+2014 dan U+2013.

## Struktur

- lib/app: tema, router 5 tab, copy rules
- lib/core: alarm channel, waktu WIB, PIN HMAC, log lokal
- lib/data/local: Drift SQLite, seed, sync paket, backup ZIP, kwitansi PDF
- lib/features: home, schedule, teacher, attendance, material, billing, profile, auth
- lib/shared/widgets: kartu sesi, empty dan error, bar profil
- tools/forbid_scan.dart: linter teks anti AI slop karakter
- plan.md: spesifikasi produk. RELEASE_V01.md: checklist rilis dan SOP.

## Aturan keras

1. Bahasa Indonesia lugas. Jam 15.30 WIB. Tanggal Senin, 13 Okt 2026.
2. Tanpa karakter U+2014 dan U+2013 di semua string pengguna dan kode.
3. Guru perempuan wajib Terverifikasi sebelum bisa dijadwalkan. Verifikasi manusia, bukan AI.
4. Alarm lokal exact via Kotlin. Tes bunyi sebelum hari H.
5. Backup ZIP tiap 7 hari ke 2 media. Kartu PIN owner di amplop fisik.

## Rilis

Lihat RELEASE_V01.md untuk checklist 15 poin, beta 7 hari, dan rollback biner.
