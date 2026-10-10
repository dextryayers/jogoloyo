# Rilis V.01.0 local - Les Jogoloyo

Versi app: 1.0.0+1. Paket: id.jogoloyo.les. Mode: 100 persen lokal, tanpa server.

## Checklist rilis (wajib centang semua)

1. 5 tab jalan 7 hari tanpa crash kritis.
2. Alarm H-30 dan H-10 tepat toleransi 1 menit di 3 HP (Xiaomi entry, Samsung mid, Oppo atau Vivo).
3. Tidak ada alarm hantu setelah batal, ubah, restore, import.
4. 0 sesi aktif dengan guru P non ACTIVE. Query: activeSessionsWithUnverifiedFemaleTeacher = 0.
5. QR basi ditolak. PIN dibatasi 5 salah. Paket palsu ditolak.
6. Billing buat sampai kwitansi lolos di HP sama dan beda HP via file.
7. Distribusi 200 sesi import tanpa duplikat. Konflik tampil dialog benar.
8. Backup dan restore 10 kali sukses termasuk foto dan alarm.
9. CSV dan PDF terbuka di HP dan laptop.
10. Start dingin di bawah 3 detik. AAB di bawah 30 MB.
11. 0 karakter U+2014 dan U+2013. Bukti: dart run tools/forbid_scan.dart OK.
12. Tidak ada kunci di repo. Kunci les hanya di secure storage dan QR pairing.
13. Audit tampil 50 terbaru dan bisa diekspor.
14. Kartu PIN owner fisik dicetak dan disimpan di amplop.
15. SOP 1 halaman diserahkan ke admin.

## Perintah verifikasi cepat

```
flutter analyze
flutter test
dart run tools/forbid_scan.dart
```

Target: analyze No issues, test 15/15 passed, lint OK 70+ file.

## Beta 7 hari

Peserta: 10 siswa, 3 guru (min 2 perempuan), 1 admin, 2 ortu.
Sebagian HP bersama, sebagian beda HP via paket WA atau Bluetooth.
Tugas harian: cek alarm bunyi, verifikasi, absen QR, materi offline, bayar, sync paket.
Metrik lolos: crash free di atas 99.2 persen, 0 telat tanpa alarm, 0 guru pending bisa mengajar, import sukses di atas 98 persen, backup 100 persen.

## Rollback

Jika crash kritis di atas 2 persen sesi pada 24 jam pertama: tarik rilis ke internal, instal ulang APK stabil sebelumnya, restore ZIP terakhir. Data setelah backup terakhir input ulang manual. Umumkan via WA grup les dengan kalimat baku.

## SOP harian admin (ringkas)

Pagi 10 menit: dashboard, review guru pending, verifikasi bayar waiting.
Mingguan 30 menit: ekspor distribusi ke grup WA, import setoran, ekspor CSV ke laptop, backup ZIP ke 2 media.
Bulanan: tagihan tanggal 1, pengumuman H-3, rekap H I S A untuk ortu, cek penyimpanan 500 MB, arsip identitas 90 hari.

Kalimat baku:
- Foto ditolak: Foto belum memenuhi ketentuan. Mohon unggah ulang dengan jilbab menutup rambut di cahaya terang.
- Bayar ditolak: Bukti tidak terbaca. Mohon foto ulang struk dengan nominal dan tanggal jelas.
- Paket rusak: File tidak valid atau tidak lengkap. Minta kirim ulang file asli dari pengirim.
