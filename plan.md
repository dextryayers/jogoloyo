# LES JOGOLOYO - PLAN V.01.0 LOCAL

> Status: SIAP EKSEKUSI
> Versi dokumen: V.01.0-local.1
> Pemilik produk: Admin Les Jogoloyo
> Stack: Flutter stabil + Kotlin native Android + 100 persen penyimpanan lokal. Tanpa database server. Tanpa internet wajib.
> Prinsip keras: semua fitur tetap bekerja penuh secara lokal, anti AI slop, tanpa karakter U+2014 di semua output pengguna dan kode.

## Changelog Dokumen

* V.01.0-local.1: Migrasi penuh dari backend server ke lokal only. Auth PIN lokal, DB Drift SQLite lokal, file app private, sync antar HP via paket file dan QR, backup ZIP, semua fitur F1 sampai F8 dipetakan ulang agar jalan tanpa server.
* V.01.0-deep.1: Versi server Supabase. Diarsipkan. Tidak dipakai lagi untuk V.01.0.
* V.01.0 awal: MVP 5 tab dan alarm dasar.

## Cara Membaca Dokumen Ini

1. Bagian 1 sampai 4 untuk kesepakatan produk lokal only dan aturan main.
2. Bagian 5 untuk kebijakan guru wajib berjilbab versi lokal.
3. Bagian 6 untuk alarm yang 100 persen lokal dan tidak berubah secara perilaku.
4. Bagian 7 untuk 5 tab bawah.
5. Bagian 8 untuk pemetaan semua fitur ke penyimpanan lokal. Ini bagian kunci.
6. Bagian 9 untuk arsitektur lokal, skema Drift, kontrak channel, dan protokol sync file.
7. Bagian 10 sampai 18 untuk UI, keamanan lokal, QA, fase, rilis, SOP, risiko, dan roadmap.

Jika ada konflik dengan dokumen versi server lama, dokumen local ini yang menang.

---

# 1. Konteks Lokal Only

## 1.1 Definisi Lokal Only V.01.0

1. Tidak ada database server, tidak ada Supabase, tidak ada Ktor, tidak ada Firebase Auth, tidak ada FCM.
2. Satu satunya sumber simpan: HP pengguna. Yaitu database SQLite lokal via Drift, secure storage untuk kunci dan PIN, shared preferences untuk setelan, dan folder dokumen aplikasi untuk foto dan file.
3. Aplikasi wajib jalan penuh dalam mode pesawat setelah instal. Instal awal bisa dari APK offline.
4. Semua fitur wajib bekerja: auth peran, verifikasi guru, jadwal, alarm, absensi QR dan PIN, materi offline, tugas, kuis, billing manual, pengumuman lokal, dashboard admin, ekspor CSV, backup restore.

## 1.2 Model Perangkat yang Dipakai

Ada dua pola resmi. Pilih satu saat instalasi awal. Keduanya didukung kode yang sama.

Pola A. Satu HP Bersama di Lokasi Les (default, paling stabil):
* HP milik les ditaruh di meja admin.
* Semua peran login logout dengan PIN di HP yang sama. Contoh: admin pagi, guru check in, siswa absen via QR di HP itu atau di HP guru.
* Tidak butuh sync antar HP. Semua data satu DB. Cocok untuk V.01.0.
* Siswa yang punya HP sendiri tetap bisa instal app, tapi datanya diisi via Paket Distribusi dari HP admin (lihat Bagian 9.5).

Pola B. Banyak HP dengan Sync File Manual:
* Admin sebagai sumber kebenaran.
* Admin kirim Paket Distribusi mingguan via WA, Bluetooth, atau kabel USB. Isinya jadwal, materi metadata, pengumuman, dan tagihan.
* HP siswa import paket. HP siswa simpan absensi dan tugas secara lokal, lalu setor balik via Paket Setoran ke admin.
* Tidak ada sync otomatis. Semua eksplisit via tombol Ekspor dan Impor. Jujur ke pengguna: ada tombol, ada status, ada konflik yang bisa diselesaikan manual.

V.01.0 wajib mendukung Pola A penuh dan Pola B minimal untuk jadwal, materi, dan absensi. Pola B penuh untuk billing dan tugas masuk Fase 7.

## 1.3 Target V.01.0 Lokal dalam angka

1. 0 sesi telat tanpa alarm berbunyi pada 30 sesi uji beta.
2. 100 persen sesi aktif memakai guru ACTIVE. Query lokal harus 0 baris pelanggaran sebelum rilis.
3. Ekspor CSV absensi selesai di bawah 2 menit untuk 500 baris di HP entry.
4. Start dingin di bawah 3 detik di RAM 3 GB. Ukuran AAB di bawah 30 MB karena tanpa SDK server.
5. Backup 500 MB data dalam di bawah 3 menit dan restore berhasil 100 persen pada uji 10 kali.
6. Import paket 200 sesi tanpa duplikat dan tanpa alarm hantu.
7. 0 temuan karakter U+2014 pada audit string.

## 1.4 Yang Masuk dan Keluar

Masuk:
* Android 10 sampai 15, instal APK atau AAB offline.
* Semua 5 tab bawah.
* Alarm exact lokal via Kotlin.
* QR rotating yang ditandatangani kunci lokal.
* Kuis PG dengan nilai otomatis lokal.
* Billing manual dengan foto bukti lokal dan kwitansi PDF lokal.
* Backup ZIP dan restore, ekspor CSV, paket distribusi.

Keluar (dilarang di V.01.0 lokal):
* OTP WA, login Google, auth server apapun.
* Push notification dari server. Pengingat hanya dari alarm lokal dan pengumuman lokal.
* Payment gateway, upload cloud, sinkronisasi otomatis background ke cloud.
* Video call, chat bebas, AI apapun.
* Build iOS dan Web. Kode siap porting tapi rilis hanya Android.

## 1.5 Asumsi Kunci

1. Admin pegang PIN owner dan kunci backup. Jika hilang, data tidak bisa dipulihkan. Sediakan kartu cetak PIN owner di amplop.
2. Jam perangkat bisa salah. Aplikasi simpan waktu dalam UTC plus offset WIB eksplisit dan tampilkan label WIB selalu.
3. HP bisa hilang. Backup mingguan ke laptop atau flashdisk adalah SOP wajib, bukan opsional.
4. Satu nomor WA boleh dipakai banyak akun lokal karena tidak ada verifikasi server. Identitas dijamin oleh PIN plus nama plus foto, bukan nomor.

---

# 2. Persona dan Cerita Pengguna Versi Lokal

Persona tetap sama: Siswa Sinta, Guru Rina, Admin Budi, Ortu Ibu Sinta. Bedanya semua bekerja tanpa internet.

Cerita yang disesuaikan:

US-01L. Sebagai siswa pada HP bersama, saya bisa ganti profil dengan PIN 6 digit dalam 5 detik, lalu lihat kartu Les Berikutnya, sehingga antrean di meja admin cepat.

US-02L. Sebagai siswa dengan HP sendiri, saya bisa import Paket Jadwal dari admin via file, lalu alarm saya tetap bunyi tanpa internet.

US-03L. Sebagai guru, saya bisa check in dan tampilkan QR absensi tanpa internet. QR tetap berganti tiap 60 detik.

US-04L. Sebagai siswa tanpa internet, saya bisa pindai QR guru dan tercatat hadir di HP guru dan di HP saya sebagai bukti ganda.

US-05L. Sebagai guru perempuan, saya bisa daftar offline, unggah foto lokal, dan menunggu review admin di HP yang sama atau via paket file jika beda HP.

US-06L. Sebagai admin, saya bisa backup seluruh data ke ZIP, pindah ke HP baru, dan restore penuh termasuk foto dan alarm.

US-07L. Sebagai ortu, saya bisa lihat rekap anak di HP bersama atau di HP sendiri dari paket yang diimport, tanpa butuh akun cloud.

US-08L. Sebagai admin, saya bisa ekspor CSV dan PDF kwitansi ke folder Download agar bisa dicetak di warnet tanpa internet.

---

# 3. Aturan Global Produk

## 3.1 Anti AI Slop

Dilarang:
1. Gradasi ungu biru generik, kartu kaca tanpa fungsi, ikon robot untuk fitur non robot.
2. Headline kosong. Wajib fakta: mapel, jam, ruang, tindakan.
3. Placeholder Inggris. Contoh larangan: Coming soon. Ganti: Belum ada jadwal. Hubungi admin.
4. Emoji di area formal: jadwal, absensi, verifikasi, pembayaran. Batas 0 emoji.
5. Emoji di banner promo: maks 1.
6. Ilustrasi tanpa fungsi. Hanya untuk panduan 3 langkah, empty state dengan aksi, status sukses atau gagal.
7. Copy generik seperti pengalaman belajar terbaik. Wajib spesifik seperti Les Matematika kelas 8, Sabtu 15.30, Ruang A.

Wajib:
1. Font tunggal Plus Jakarta Sans dengan fallback sistem.
2. Palet kunci: primer hijau joglo 0xFF1B5E20, kertas 0xFFFAF7F0, arang 0xFF1A1A1A, sukses 0xFF2E7D32, bahaya 0xFFC62828, peringatan 0xFFEF6C00. Maks 2 aksen per layar.
3. Tombol penting min 48 dp: Atur Alarm, Check In, Pindai, Unggah Bukti.
4. Skeleton saat loading daftar. Empty state selalu ada aksi.
5. Semua error berisi sebab plus aksi. Contoh: Alarm mati karena izin ditolak. Buka Pengaturan.

## 3.2 Aturan Karakter dan Bahasa

1. Larangan: karakter U+2014 tidak boleh muncul di string pengguna, notifikasi, PDF, CSV, komentar kode, nama file tampil, dan isi paket JSON.
2. Larangan tambahan V.01.0: karakter U+2013 juga dilarang agar konsisten. Gunakan tanda hubung biasa (-).
3. Pengganti baku:
   * Rentang jam: 15.30 - 17.00
   * Penjelas: gunakan titik dua atau koma. Contoh: Jadwal: Sabtu, Ruang A
4. Lint wajib: tools forbid_scan.dart memindai lib, android, assets strings. Gagalkan commit jika ada temuan. Tidak ada pengecualian selain penyebutan kode U+2014 tanpa glyph pada dokumen ini.
5. Bahasa Indonesia lugas. Jam 24 jam WIB. Tanggal: Senin, 13 Okt 2026.
6. Contoh copy patuh:
   * H-30: 30 menit lagi: Matematika mulai 15.30. Aktifkan suara HP.
   * H-10: 10 menit lagi masuk kelas. Siapkan buku dan alat tulis.
   * Saat mulai: Saatnya masuk: Matematika di Ruang A. Tekan Saya Sudah di Lokasi.
   * QR basi: Kode kedaluwarsa. Minta kode baru ke guru.
   * Bukti bayar: Bukti diterima dan tersimpan di HP ini. Tunjukkan ke admin untuk verifikasi.

## 3.3 Aksesibilitas dan Kinerja Lokal

1. Hormati font sistem sampai 130 persen tanpa pecah.
2. Label semantik untuk screen reader pada 5 tab dan tombol utama.
3. Anggaran lokal:
   * DB di bawah 200 MB untuk 1 tahun operasi single lokasi. Lebih dari itu wajib arsip.
   * Cache file di bawah 500 MB. Ada layar Kelola Penyimpanan.
   * Buka tab Jadwal di bawah 800 ms untuk 500 sesi lokal.
   * Pindai QR di bawah 2 detik di cahaya kelas.

---

# 4. Navigasi Bawah Tetap 5 Tab

```
[Beranda] [Jadwal] [Guru] [Materi] [Saya]
```

Routes go_router StatefulShellRoute, tanpa server:

```
/home
/schedule
/schedule/:sessionId
/schedule/:sessionId/alarm
/teachers
/teachers/:teacherId
/teachers/review (PIN admin)
/materials
/materials/:materialId
/assignments/:assignmentId
/profile
/profile/accounts (ganti profil lokal)
/profile/backup
/profile/bills
/profile/bills/:billId
/profile/sync (ekspor dan impor paket)
```

Guard lokal:
* Belum ada akun: wajib ke /setup awal (buat owner) lalu /profile/accounts.
* Guru PENDING hanya bisa buka Saya dan status tunggu.
* ORTU mode baca. Tombol tulis disembunyikan.
* Aksi sensitif (review guru, verifikasi bayar, hapus data, restore) butuh PIN admin ulang.

Perilaku:
1. Ketuk tab aktif untuk scroll ke atas.
2. Pindah tab tidak reset filter.
3. Notifikasi alarm membuka detail sesi langsung.
4. Mode HP Bersama: ada bar profil aktif di atas (nama plus peran plus tombol Ganti) agar tidak salah akun.

Isi tiap tab sama lengkap seperti versi deep, tapi semua dari DB lokal:
* Beranda: Les Berikutnya, ringkasan hadir 7 hari, tagihan aktif, pengumuman lokal 3 terbaru, kartu backup jika belum backup 7 hari.
* Jadwal: kalender minggu, filter Semua, Saya, Berlangsung, Selesai, Izin, kartu sesi dengan ikon alarm, detail dengan tombol Alarm, Materi, Absen atau Izin.
* Guru: daftar ACTIVE plus label Terverifikasi Jogoloyo, profil ringkas, sesi 14 hari. Untuk guru: Check In dan Check Out. Untuk admin: tab Antrian Review dengan badge.
* Materi: Mapel, Bab, Item PDF atau gambar atau tautan video (tautan hanya info, butuh internet jika dibuka), tugas dengan tenggat, kuis PG.
* Saya: profil aktif, daftar akun di HP ini, PIN, tagihan, pengaturan alarm plus Tes Alarm, sync ekspor impor, backup restore, kelola penyimpanan, bantuan, versi.

---

# 5. Kebijakan Guru Wajib Berjilbab Versi Lokal

## 5.1 Prinsip

1. Berlaku untuk akun GURU gender P. Tetap diverifikasi manusia (admin). Dilarang penilaian otomatis AI.
2. Semua foto simpan di folder private aplikasi, bukan galeri umum. Path tidak bisa ditebak. Tidak diupload ke mana pun.
3. Status sama seperti versi deep agar siap migrasi server nanti:

```
DRAFT -> PENDING -> ACTIVE
              -> REJECTED -> PENDING
ACTIVE -> SUSPENDED -> PENDING
ACTIVE -> INACTIVE
```

4. Setiap transisi tulis ke tabel audit lokal dengan actor, waktu, alasan.

## 5.2 Alur Lokal Pola A (satu HP)

1. Guru buat akun di HP les dengan nama, mapel, gender, PIN.
2. Ambil foto profil via kamera (wajib kamera, dilarang dari galeri untuk foto awal agar asli).
3. Ambil foto identitas via kamera. Tampilkan hanya ke admin.
4. Centang pernyataan plus nama terang. Status jadi PENDING.
5. Admin buka Antrian Review di HP yang sama, lihat foto besar, pilih Setujui atau Tolak dengan alasan baku:
   * Foto tidak jelas
   * Rambut masih terlihat
   * Bukan foto asli wajah
   * Dokumen tidak terbaca
   * Lainnya (min 10 karakter)
6. Jika setuju: ACTIVE plus label Terverifikasi Jogoloyo. Jika tolak: REJECTED plus alasan. Maks 3 unggah ulang dalam 7 hari, setelah itu kunci dan harus via admin owner.

## 5.3 Alur Lokal Pola B (beda HP)

1. Guru daftar di HP sendiri. Data PENDING tersimpan lokal di HP guru.
2. Guru tekan Ekspor Pengajuan. Hasilnya file `pengajuan_guru_[nama]_[waktu].jogoloyo` berisi foto terkompresi plus data hash.
3. File dikirim ke admin via WA atau Bluetooth.
4. Admin tekan Impor Pengajuan di layar Review. Foto tampil. Admin putuskan Setujui atau Tolak.
5. Admin tekan Ekspor Hasil Review. File hasil dikirim balik ke guru. Guru import dan statusnya jadi ACTIVE atau REJECTED.
6. Anti tipu: setiap paket ada ID pengajuan, hash SHA-256 foto, dan tanda tangan HMAC dengan kunci les. Kunci les dibuat saat setup owner dan dibagikan via QR sekali. HP yang tidak punya kunci les tidak bisa buat paket valid.
7. Jika paket dimodifikasi, import ditolak dengan pesan: Paket tidak valid. Minta file asli dari pengirim.

## 5.4 Check In Harian

1. Layar check in tampilkan foto resmi kecil.
2. Checkbox baku: Saya hadir dengan busana sesuai ketentuan, berjilbab rapi dan menutup rambut.
3. Tanpa centang, tombol nonaktif.
4. Simpan waktu UTC, nama ruang, dan ID sesi. Tidak ada GPS presisi di V.01.0.

## 5.5 Privasi Lokal

1. Foto identitas hanya dibuka setelah PIN admin. Tidak tampil di profil siswa.
2. Dilarang ekspor foto identitas ke paket siswa. Paket siswa hanya bawa foto profil resmi guru ACTIVE.
3. Retensi: foto identitas boleh dihapus setelah 90 hari ACTIVE tanpa sengketa via tombol Hapus Dokumen yang mencatat log.
4. Jika HP hilang: data hilang. Mitigasi hanya backup ZIP terenkripsi plus PIN. Tidak ada reset via cloud.

---

# 6. Alarm Pengingat Jam Masuk Versi Lokal Penuh

Perilaku sama seperti versi deep, tapi 100 persen tanpa FCM dan tanpa server. Justru lebih andal.

## 6.1 Model Alarm per Sesi per Profil Lokal

```
session_alarms_local:
  session_id, profile_id, offsets [60,30,10], enabled, last_fired, updated_at
```

* Default siswa: H-30 aktif, H-10 aktif.
* Default guru: H-60 aktif, H-30 aktif.
* Default ortu: H+10 info telat jika anak belum hadir (dibaca dari DB lokal HP yang sama, atau dari paket setoran terakhir jika beda HP).
* Ubah per sesi atau sebagai default profil.

## 6.2 Matriks Perilaku Lokal

* H-60: notifikasi info jika aktif.
* H-30: pengingat suara.
* H-10: prioritas tinggi plus getar.
* H-0: ongoing plus aksi Saya di Lokasi dan Mulai Sesi.
* H+10 belum absen: pengingat kedua di HP yang sama. Jika beda HP, ortu lihat status saat import paket terbaru. Tidak ada push otomatis antar HP karena tanpa server. Ini batas jujur yang ditulis di UI: Status ortu diperbarui setelah import paket terbaru.
* Jadwal berubah: semua alarm sesi itu dijadwal ulang dalam 60 detik di HP yang menyimpan perubahan. HP lain ikut berubah setelah import paket revisi.
* Jadwal batal: semua alarm sesi itu dibatalkan. Tidak ada alarm hantu.

## 6.3 Kotlin Tetap Sama, Lebih Sederhana

Modul Android tetap:
* AlarmScheduler.kt, AlarmReceiver.kt, BootReceiver.kt, NotificationHelper.kt, AlarmStore.

Channel tetap `jogoloyo/alarm/v1` dengan metode:
* scheduleSessionAlarm, cancelSessionAlarm, cancelAllAlarms, testAlarm, openExactAlarmSettings, arePermissionsGranted, rescheduleAllOnBoot.

Bedanya:
1. Tidak ada event FCM. Pemicu reschedule hanya dari perubahan DB lokal dan dari hasil import paket.
2. ID alarm unik dari hash sessionId plus profileId plus offset agar Pola A dengan banyak profil di 1 HP tidak tabrakan.
3. Log 100 entri terakhir simpan di prefs untuk diagnosis: dijadwalkan, bunyi, batal, terlewat.

## 6.4 Izin dan OEM

Sama ketat seperti versi deep:
* Android 13 minta POST_NOTIFICATIONS kontekstual setelah login pertama.
* Android 12 ke atas tangani SCHEDULE_EXACT_ALARM dengan tombol Buka Pengaturan.
* Android 14 tangani full screen intent. Jika ditolak, fallback heads up.
* Panduan baterai: Xiaomi Autostart, Samsung unrestricted, Oppo Vivo background allow.
* Label jujur di UI: Presisi, Tidak presisi, Mati.
* Tombol Tes Alarm info dan urgent wajib ada di tab Saya dan di sheet alarm sesi.

## 6.5 Uji Alarm Lokal Wajib Lolos

1. Bunyi saat app ditutup total.
2. Bunyi setelah reboot tanpa buka app.
3. H-30 dan H-10 tepat toleransi 1 menit di 3 HP beda merek.
4. Ganti profil di HP bersama tidak mematikan alarm profil lain.
5. Batal sesi membatalkan semua alarm profil untuk sesi itu.
6. Restore dari backup ZIP menjadwal ulang semua alarm aktif otomatis.
7. Import paket revisi jadwal memperbarui alarm tanpa duplikat.

---

# 7. Spesifikasi Fitur per Modul Versi Lokal

Semua modul di bawah bekerja tanpa internet. Kolom Simpan menunjukkan lokasi.

## F1. Auth Lokal Multi Profil dan PIN

Pengganti OTP:
1. Setup awal: buat akun OWNER dengan nama les, nama owner, PIN 6 digit. Kunci les (32 byte random) dibuat dan simpan di secure storage. Tampilkan QR kunci les sekali untuk pairing HP lain.
2. Admin buat akun peran: ADMIN_OPS, GURU, SISWA, ORTU. Setiap akun punya: id lokal uuid, nama, peran, PIN hash (argon2 atau bcrypt via package), foto opsional, aktif atau nonaktif.
3. Login atau ganti profil: pilih nama lalu masukkan PIN. Maks 5 salah lalu kunci 5 menit. Semua percobaan dicatat.
4. PIN owner untuk: buka review guru, verifikasi bayar di atas 500 ribu, ekspor kunci les, hapus data, restore.
5. Lupa PIN: hanya owner bisa reset PIN akun lain setelah masukkan PIN owner. Tidak ada reset via WA.
6. Nomor WA hanya sebagai info kontak, bukan identitas. Boleh kosong.

Simpan: tabel profiles, tabel pin_attempts, secure storage untuk kunci les dan hash.

DoD:
* Ganti profil di bawah 5 detik.
* Akses route admin tanpa PIN ditolak dan tercatat.
* Tidak ada PIN plaintext di log dan di DB. Hanya hash.

## F2. Profil, Anak Tertaut Lokal

1. Siswa punya kode tautan 6 digit yang dibuat lokal, TTL 24 jam, bisa buat ulang.
2. Di HP yang sama: ortu pilih Klaim lalu pilih anak, selesai tanpa file.
3. Beda HP: siswa Ekspor Kartu Anak (QR berisi id anak plus kode klaim plus hash). Ortu pindai di HP sendiri. Atau via file paket.
4. Batas: 1 anak maks 2 ortu, 1 ortu maks 4 anak.
5. Melepas tautan bisa oleh pemilik akun anak, ortu, atau admin. Tercatat.

## F3. Jadwal Lokal

Field inti sama, tapi tambah:
```
sessions_local:
  id, class_id, teacher_id, subject, level, start_utc, end_utc, room, note,
  status, revision, updated_at, origin_device_id, deleted_flag
```

Aturan:
1. Durasi 60, 90, 120. Di luar itu wajib catatan.
2. Cegah bentrok di kode repository sebelum insert dan update. Cek overlap interval [start, end) untuk teacher sama dan room sama pada status scheduled dan ongoing.
3. Batal butuh alasan min 10 karakter. Data tidak dihapus fisik, hanya flag batal plus alasan agar audit dan alarm bisa dibatalkan bersih.
4. Revisi: setiap ubah naikkan revision. Saat import paket, revision lebih besar menang. Jika sama tapi beda isi, tampilkan dialog konflik dengan pilihan: Pakai paket atau Pertahankan HP ini. Tidak ada auto timpa diam diam.
5. Tampilkan label Diubah jika revision lebih dari 1.

DoD:
* 500 sesi lokal scroll lancar.
* 20 kasus bentrok ditolak 100 persen.
* Import paket revisi tidak buat duplikat dan alarm ikut ulang.

## F4. Absensi QR dan PIN Tanpa Server

Kunci tanda tangan:
* Kunci les 32 byte dipakai HMAC-SHA256 untuk QR dan paket.
* Kunci simpan di secure storage. Ekspor kunci hanya via QR pairing dengan PIN owner.

QR sesi:
1. Guru tekan Tampilkan Kode di detail sesi. HP guru buat payload:
```
{
  v: 1,
  session_id: abc,
  epoch_60: 1730000000,
  pin_hint: false,
  sig: hmac(session_id + epoch_60)
}
```
Dikodekan sebagai QR JSON ringkas plus base64. Refresh tiap 60 detik.
2. Siswa tekan Pindai untuk Hadir. Verifikasi sig dengan kunci les. Tolak jika epoch basi lebih dari 90 detik toleransi jam.
3. Jika kamera bermasalah: guru tampilkan PIN 6 digit yang berubah tiap 10 menit (HMAC dari session_id plus epoch_600). Siswa ketik PIN. Batas 5 salah per sesi.
4. Hasil simpan ganda:
   * Di HP guru (atau HP bersama): tabel attendance sebagai kebenaran.
   * Di HP siswa (jika beda HP): tabel my_proof sebagai bukti. Bukti bisa diekspor sebagai Paket Setoran dan diimport admin untuk melengkapi rekap.
5. Status auto alpa H+30 untuk yang tidak ada catatan di DB admin.
6. Ekspor CSV dari HP admin dengan header baku dan encoding UTF-8 BOM.

Anti curang lokal:
* Screenshot QR basi ditolak karena epoch.
* PIN brute force dibatasi.
* Tidak ada spoof tanpa kunci les. Paket tanpa sig valid ditolak.

## F5. Materi, Tugas, Kuis Lokal

Materi:
1. Admin tambah materi: PDF atau gambar maks 25 MB dari file picker. Simpan di app documents dengan nama hash. Metadata di DB.
2. Video hanya sebagai tautan teks plus judul. Dibuka butuh internet, tapi metadata dan judul tetap tampil offline dengan label Butuh internet.
3. Tandai penting untuk selalu disimpan. Batas cache 500 MB dengan layar Kelola Penyimpanan: hapus per mapel, hapus cache, lihat ukuran.
4. Revisi materi: simpan versi baru plus label Revisi 2. Versi lama read only 7 hari lalu boleh dihapus.

Tugas:
1. Admin atau guru buat tugas: judul, deskripsi, due_utc, max_score.
2. Pola A: siswa kumpul di HP yang sama via file picker maks 10 MB. Pola B: siswa kumpul di HP sendiri lalu Ekspor Setoran Tugas dan admin import. Status: Belum kumpul, Terkumpul, Dinilai, Terlambat.
3. Telat: masih bisa kumpul dengan label Terlambat plus potongan default 10 persen per hari maks 3 hari. Aturan bisa diubah per mapel.

Kuis PG:
1. Bank soal lokal per kuis: 10 soal, 4 opsi, kunci, pembahasan teks.
2. Acak soal dan opsi per percobaan. Seed simpan agar bisa diaudit.
3. 1 nilai resmi plus 1 latihan. Percobaan kedua butuh PIN guru atau admin di HP yang sama, atau kode izin 6 digit jika beda HP.
4. Nilai otomatis, simpan answers JSON, started_at, submitted_at.

DoD:
* PDF 25 MB terbuka tanpa OOM di RAM 3 GB.
* Mode pesawat: materi yang sudah disimpan tetap terbuka.
* Nilai konsisten 100 percobaan.

## F6. Billing Manual Lokal

1. Admin buat tagihan massal per periode: pilih siswa, nominal integer rupiah, periode teks baku contoh 2026-10. Constraint unik student plus period cegah dobel.
2. Rekening resmi simpan di setelan les. Ubah butuh PIN owner.
3. Pola A: siswa serahkan bukti dengan foto di HP yang sama. Status waiting_review.
4. Pola B: siswa foto bukti di HP sendiri, Ekspor Paket Bayar, admin import. File bukti dikemas dalam paket sebagai JPG terkompresi maks 2 MB per bukti agar paket tidak bengkak. Paket besar dipecah per 25 bukti.
5. Admin review: Setujui atau Tolak beralasan. Nominal besar butuh PIN owner.
6. Kwitansi PDF dibuat lokal dengan nomor `JGL-202610-0001`, nama, periode, nominal, tanggal verifikasi, nama verifikator, label LUNAS. Simpan di Download dan di app documents.
7. Tidak ada hapus tagihan. Hanya batal dengan alasan dan audit.

## F7. Pengumuman Lokal

1. Admin tulis pengumuman: judul maks 80, isi maks 1000, target semua atau per kelas, 1 lampiran opsional maks 5 MB.
2. Di HP yang sama langsung tampil di Beranda maks 3 terbaru.
3. Beda HP: ikut dalam Paket Distribusi. HP siswa tampilkan label Diperbarui: [tanggal import] agar jujur.
4. Komentar mati di V.01.0.
5. Pengingat bayar H-3 dibuat sebagai pengumuman otomatis lokal dari data tagihan, bukan push server.

## F8. Dashboard Admin dan Audit Lokal

Dashboard kartu lokal:
* Sesi hari ini, guru pending, tunggakan aktif, hadir hari ini.
* Peringatan backup jika terakhir lebih dari 7 hari.
* Peringatan penyimpanan jika di atas 80 persen.

Log audit lokal tabel audit_log:
* login, ganti profil, buat jadwal, ubah jadwal, batal sesi, review guru, review bayar, ekspor, impor, backup, restore, hapus dokumen.
* Tampilkan 50 terbaru plus filter. Ekspor log ke CSV untuk arsip.

Peran admin lokal:
* owner: semua.
* admin_ops: jadwal, absensi, materi, pengumuman. Tidak bisa ubah rekening, tidak bisa restore hapus, tidak bisa ekspor kunci les.

---

# 8. Arsitektur Teknis Lokal Rinci

## 8.1 Diagram

```
Flutter UI (Dart)
 -> Riverpod
 -> Repository interface (abstract, siap ganti server nanti)
 -> LocalDataSource Drift SQLite + FileStore + SecureStore
 -> Kotlin Alarm via MethodChannel (jadwal ulang dari DB lokal)

Sync antar HP (tanpa server):
 Admin HP -> Ekspor Paket .jogoloyo (zip: manifest.json + data.json + files/) -> WA/BT/USB
 Siswa HP -> Impor Paket -> validasi HMAC -> upsert by id + revision -> reschedule alarm
 Siswa HP -> Ekspor Setoran (absen bukti, tugas, bayar) -> Admin import -> review
```

## 8.2 Versi Pin Lokal (tanpa SDK cloud)

1. Flutter stable, Dart null safety.
2. Kotlin 1.9.x, compileSdk 34, minSdk 29, targetSdk 34.
3. Riverpod 2.x, go_router 13 atau 14, drift 2.x plus sqlite, flutter_secure_storage, shared_preferences, file_picker, image (kompresi), qr_flutter, mobile_scanner, pdf, csv, archive (zip), share_plus, path_provider, flutter_local_notifications.
4. Tanpa supabase, tanpa firebase_core, tanpa firebase_messaging. Jika template lama masih ada, hapus agar AAB ramping.
5. Kunci semua versi di pubspec.lock dan catat di CHANGELOG.

## 8.3 Struktur Folder

```
lib/
  main.dart
  flavors.dart
  app/router.dart
  app/theme.dart
  app/constants.dart
  app/strings.dart
  core/time/wib.dart
  core/text/forbid_scan.dart
  core/security/pin_hash.dart
  core/security/hmac.dart
  core/alarm/alarm_service.dart
  data/local/app_db.dart (drift)
  data/local/daos/
  data/repos/ (interface + impl lokal)
  data/sync/
    export_service.dart
    import_service.dart
    package_model.dart
  features/auth/
  features/home/
  features/schedule/
  features/teacher/
  features/material/
  features/attendance/
  features/billing/
  features/profile/backup_page.dart
  features/profile/sync_page.dart
  shared/widgets/
android/app/src/main/kotlin/id/jogoloyo/les/alarm/
  AlarmScheduler.kt
  AlarmReceiver.kt
  BootReceiver.kt
  NotificationHelper.kt
  AlarmStore.kt
assets/strings/id.arb
tools/forbid_scan.dart
```

## 8.4 Skema Drift Lokal (inti)

Tabel:
* profiles(id, role, name, pin_hash, gender, photo_path, status, created_at)
* teacher_verifications(id, teacher_id, photo_path, id_doc_path, status, reviewer_id, reason, attempts, created_at, decided_at)
* verification_audit(id, verification_id, actor_id, from_status, to_status, reason, created_at)
* classes(id, subject, level, room_default)
* sessions(id, class_id, teacher_id, start_utc, end_utc, room, note, status, revision, origin_device, updated_at, cancel_reason)
* session_alarms(session_id, profile_id, offsets_json, enabled, last_fired, updated_at)
* attendance(session_id, profile_id, status, method, created_at) unique(session_id, profile_id)
* my_proof(session_id, payload_json, created_at) di HP siswa sebagai bukti pindai
* materials(id, class_id, title, kind, file_path_or_url, size, revision, important, created_at)
* assignments(id, class_id, title, desc, due_utc, max_score)
* submissions(id, assignment_id, student_id, file_path, score, status, submitted_at)
* quizzes(id, class_id, title, duration_min)
* questions(id, quiz_id, text, options_json, answer_idx, explain)
* attempts(id, quiz_id, student_id, score, answers_json, started_at, submitted_at, kind)
* bills(id, student_id, period, amount_int, status, proof_path, reviewer_id, reviewer_note, created_at) unique(student_id, period)
* announcements(id, title, body, target, attachment_path, created_at)
* parent_links(id, parent_id, child_id, created_at)
* audit_log(id, actor_id, action, detail, created_at)
* sync_state(id, last_export_at, last_import_at, device_id)

Aturan DB:
1. Foreign key aktif. Hapus fisik dilarang untuk sessions, bills, attendance. Gunakan status atau flag.
2. Semua waktu simpan UTC ISO. Tampil konversi WIB.
3. Foto dan file simpan path relatif ke app documents. Jangan simpan blob besar di SQLite.
4. Migrasi Drift dari versi 1 ke 2 dst wajib diuji dengan data nyata beta.

Contoh validasi bentrok (Dart, bukan SQL server):
```dart
bool overlap(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
}
// Tolak jika ada sesi aktif dengan teacher sama overlap.
// Tolak jika ada sesi aktif dengan room sama overlap.
```

## 8.5 Format Paket Sync .jogoloyo

Paket adalah ZIP dengan nama:
```
jogoloyo_[jenis]_[yyyyMMdd_HHmm]_[device4].zip
```
Jenis: distribusi, setoran_absen, pengajuan_guru, hasil_review, setoran_tugas, setoran_bayar, backup_full.

Isi ZIP:
```
manifest.json
data.json
files/ (foto dan file yang dirujuk, nama hash)
```

manifest.json contoh:
```json
{
  "v": 1,
  "kind": "distribusi",
  "from_device": "A1B2",
  "created_utc": "2026-10-12T02:00:00Z",
  "counts": {"sessions": 42, "materials": 10},
  "sha256_data": "abc...",
  "sig": "hmac_sha256_hex"
}
```

data.json berisi array per tabel dengan revision. Import upsert by id. Revision besar menang. Jika revision sama tapi hash beda, tampilkan konflik manual.

Validasi import:
1. Cek ZIP bisa dibuka dan manifest v didukung.
2. Cek sha256_data cocok.
3. Cek sig dengan kunci les. Jika tidak cocok, tolak.
4. Cek tiap id valid uuid dan waktu valid.
5. Tulis ke DB dalam transaksi. Jika 1 baris gagal, rollback paket itu dan tampilkan baris penyebab.
6. Setelah sukses, jadwal ulang alarm dan tampilkan ringkasan: 42 sesi diperbarui, 2 konflik perlu pilihan, 0 alarm hantu.

Batas paket:
* Distribusi mingguan target di bawah 20 MB tanpa file besar. File besar dikirim terpisah via USB.
* Setoran bayar dipecah per 25 bukti.

Kode QR pairing kunci les:
* QR berisi device_id plus kunci terenkripsi plus checksum. Pindai sekali dengan PIN owner di kedua sisi. Setelah itu kedua HP bisa saling validasi paket.

## 8.6 Kontrak MethodChannel Tetap

Channel `jogoloyo/alarm/v1`. Sama seperti versi deep, tapi tambah profileId pada ID alarm agar multi profil satu HP aman.

Dart wajib try catch dan fallback pending_sync lokal. Status alarm tidak boleh aktif palsu. Tampilkan Menunggu sinkron jika channel gagal.

## 8.7 Backup dan Restore

Backup full:
1. Tombol Backup Sekarang di Saya > Backup. Hasil ZIP berisi app.db plus files plus manifest plus kunci terbungkus (wrapped key dengan PIN owner, bukan plaintext).
2. Simpan default ke Download plus opsi Bagikan via file manager. Nama baku dengan tanggal.
3. Restore: pilih file, masukkan PIN owner, validasi, tulis ulang DB dan files, lalu reschedule semua alarm aktif. Wajib konfirmasi dua langkah karena menimpa data HP.
4. Uji restore 10 kali sebelum rilis dengan data beta.

Retensi lokal:
* Backup otomatis pengingat tiap 7 hari via alarm lokal non intrusif (notifikasi biasa, bukan exact).
* Maks 5 backup terbaru disimpan di app, selebihnya hapus dengan konfirmasi.

---

# 9. Sistem UI dan Komponen Lokal

Token sama seperti versi deep. Tambahan khusus lokal:

1. Bar profil aktif selalu tampil di HP bersama: Nama plus Peran plus tombol Ganti. Warna beda per peran agar tidak salah input nilai atau absen.
2. Lencana Offline First di Beranda: Data tersimpan di HP ini. Terakhir backup: [tanggal]. Jika lebih dari 7 hari, warna peringatan.
3. Layar Sync: dua tombol besar Ekspor dan Impor plus riwayat 20 terakhir (nama file, waktu, hasil).
4. Layar Kelola Penyimpanan: total DB, total files, cache, tombol Hapus cache, Hapus materi per mapel.
5. Empty state spesifik lokal. Contoh: Belum ada paket diimport. Minta file distribusi dari admin via WA.
6. Error paket spesifik: Paket tidak valid, Paket kedaluwarsa revisi, File lampiran hilang. Minta kirim ulang.

Komponen wajib:
* SessionCard, AlarmSheet, VerifyQueueCard, BillCard, EmptyState, ErrorView, AppBottomBar 5 item, ProfileBar, SyncCard, StorageBar.

---

# 10. Keamanan dan Privasi Lokal

1. PIN hash dengan salt per akun. Tidak ada plaintext. Kunci les di secure storage, bukan prefs biasa.
2. Foto identitas di folder app private dengan mode 600. Tidak muncul di galeri. Buka butuh PIN admin.
3. Kunci les hanya diekspor via QR pairing dengan PIN owner di kedua sisi. Dilarang kirim kunci via teks WA.
4. Paket file selalu HMAC. Terima tolak jika sig salah.
5. Backup ZIP terenkripsi AES dengan kunci dari PIN owner plus salt. Tanpa PIN benar, tidak bisa restore. Tulis peringatan ini di UI backup.
6. Log audit lokal untuk semua aksi sensitif. Ekspor log untuk arsip.
7. Jika HP dijual: wajib Hapus Total dari menu dengan PIN owner yang menghapus DB, files, secure storage, dan alarm. Sediakan checklist hapus.
8. Tidak ada pelacakan iklan. Analitik hanya log lokal 100 entri alarm untuk diagnosis, tanpa kirim ke server.

---

# 11. Kualitas dan Uji Lokal

## 11.1 Unit 40 kasus (tanpa server)

* Parsing UTC dan WIB, batas hari, format rupiah, CSV escape.
* Overlap 20 kasus.
* State machine verifikasi semua transisi.
* HMAC QR valid, basi, palsu.
* Aturan import: revision menang, konflik Terdeteksi, duplikat tidak ganda.
* PIN hash verifikasi dan lockout.

## 11.2 Widget 15

* SessionCard semua status, AlarmSheet toggle, VerifyQueueCard, BillCard, ProfileBar, SyncCard.

## 11.3 Integrasi Lokal

* Setup owner sampai buat jadwal sampai alarm terjadwal di fake scheduler.
* Tampilkan QR di profil guru lalu pindai di profil siswa pada HP yang sama dan pastikan attendance tertulis.
* Ekspor distribusi lalu import di DB kosong dan pastikan jumlah sama dan tidak duplikat saat import dua kali.
* Backup lalu restore di folder kosong dan pastikan foto, nilai, dan alarm kembali.
* Tolak paket palsu yang sig diubah 1 byte.

## 11.4 Manual Lapangan

* 3 HP fisik beda merek untuk alarm.
* 2 HP untuk uji paket via WA dan Bluetooth: distribusi 200 sesi, setoran 50 absen, setoran bayar 25 bukti.
* Uji reboot, mode hemat, jam manual diubah, mode pesawat penuh 3 hari.
* Uji HP bersama: 20 ganti profil cepat tanpa salah catat absen.

## 11.5 Device Matrix

* Emulator Android 10, 13, 14 untuk regresi.
* Fisik min 3 unit untuk alarm plus 1 unit RAM 3 GB untuk performa dan PDF 25 MB.

---

# 12. Copywriting Siap Pakai Versi Lokal

Judul dan tombol sama, tambah khusus lokal:
* Ganti Profil, Kunci 5 menit. Coba lagi pukul [jam].
* Ekspor Paket, Impor Paket, Backup Sekarang, Pulihkan, Kelola Penyimpanan.
* Paket diterima: 42 sesi diperbarui. Alarm ikut disesuaikan.
* Paket tidak valid. Minta file asli dari pengirim.
* Ada 2 konflik jadwal. Pilih: Pakai paket atau Pertahankan HP ini.
* Backup terakhir 8 hari lalu. Segera backup ke laptop.
* Mode pesawat. Semua fitur tetap jalan dari data HP ini.

Teks kepatuhan tetap:
* Saya hadir dengan busana sesuai ketentuan, berjilbab rapi dan menutup rambut.

Semua teks masuk ke assets strings id.arb agar linter bisa memindai.

---

# 13. Fase Eksekusi Lokal Rinci

Estimasi 1 dev Flutter plus 1 admin penguji.

## FASE 0: Fondasi Lokal dan Disiplin (Hari 1 sampai 2)

0.1 Scaffold tanpa SDK cloud
* Tugas: flutter create id.jogoloyo.les, hapus firebase jika ada dari template, ikon, splash, flavor dev dan prod (staging menyatu ke dev karena lokal), gitignore.
* Output: run emulator tanpa error.
* DoD: flutter analyze 0 error, AAB dev di bawah 30 MB awal.

0.2 Disiplin teks
* Tugas: tools forbid_scan.dart untuk U+2014 dan U+2013, pre commit hook, daftar kata generik ditolak.
* DoD: commit uji melanggar terbukti ditolak.

0.3 Token UI dan router 5 tab plus ProfileBar
* Tugas: theme, SessionCard skeleton, AppBottomBar, router StatefulShellRoute, ProfileBar multi profil mock.
* DoD: 5 tab plus ganti profil mock jalan, deep link /schedule/123 terbuka.

0.4 DB lokal dan repo interface
* Tugas: Drift app_db v1, tabel inti, DAO, Repository interface agar siap migrasi server nanti tanpa ubah UI.
* Output: CRUD sesi lokal dari UI.
* DoD: migrasi v1 ke v2 uji lolos dengan data dummy.

## FASE 1: Auth PIN Multi Profil (Hari 3 sampai 4)

1.1 Setup owner dan kunci les
* Tugas: wizard setup pertama, buat owner plus PIN, buat kunci les 32 byte, QR pairing sekali.
* DoD: instal baru tanpa setup tidak bisa masuk home.

1.2 Akun peran dan ganti profil
* Tugas: buat akun, hash PIN, pilih profil plus PIN, lockout 5 salah, log percobaan.
* DoD: 20 kali ganti profil tanpa salah catat actor di audit.

1.3 Tautan ortu lokal
* Tugas: kode 6 digit TTL 24 jam, klaim di HP sama, QR kartu anak untuk beda HP.
* DoD: ortu hanya lihat anaknya pada 10 kasus.

## FASE 2: Jadwal Lokal (Hari 5 sampai 7)

2.1 Daftar dan detail dari DB lokal
* Tugas: kalender minggu, filter, SessionCard nyata, banner offline first.
* DoD: 500 sesi scroll lancar.

2.2 Buat ubah batal plus cegah bentrok lokal
* Tugas: form, cek overlap teacher dan room, alasan batal min 10 karakter, revision naik.
* DoD: 20 kasus bentrok ditolak.

2.3 Izin sakit lokal
* Tugas: form izin, status di kartu, info ke guru di HP sama.
* DoD: izin tidak dihitung alpa.

## FASE 3: Alarm Kotlin Lokal (Hari 8 sampai 11, kritis)

3.1 Channel plus scheduler multi profil
* Tugas: AlarmScheduler dengan ID hash session plus profile plus offset, Receiver, Helper, Store.
* DoD: schedule dan cancel terbukti di logcat.

3.2 Izin dan Tes Alarm
* Tugas: POST notif, exact alarm, full screen, panduan baterai, Tes info dan urgent.
* DoD: awam aktif dalam 3 langkah.

3.3 Resync lokal dan boot
* Tugas: BootReceiver, sync 14 hari saat buka, hapus alarm batal, tangani ubah jam dan ganti profil.
* DoD: reboot tetap bunyi, tidak ada alarm hantu.

3.4 Uji lapangan
* Tugas: 3 HP fisik, tutup app, reboot, tolak izin.
* DoD: toleransi 1 menit lolos.

## FASE 4: Verifikasi Guru Lokal (Hari 10 sampai 13, paralel)

4.1 Foto kamera wajib dan kompresi
* Tugas: kamera profil, kompres 2 MB, tolak blur berat, simpan private.
* DoD: foto galeri ditolak untuk pengajuan awal.

4.2 Antrian review di HP sama
* Tugas: list terlama, setuju dan tolak beralasan, audit, badge.
* DoD: PENDING ke ACTIVE dan REJECTED jalan plus log.

4.3 Paket pengajuan beda HP
* Tugas: ekspor pengajuan, import admin, ekspor hasil, import guru, validasi HMAC dan hash foto.
* DoD: paket palsu ditolak, paket valid 100 persen masuk.

4.4 Check in kepatuhan dan suspend
* Tugas: checkbox baku, blokir tanpa centang, suspend berdurasi.
* DoD: tanpa centang tidak bisa check in.

## FASE 5: Absensi QR Lokal (Hari 14 sampai 17)

5.1 QR rotating HMAC dan PIN 10 menit
* Tugas: payload epoch 60, QR refresh, PIN epoch 600, limit 5 salah.
* DoD: QR basi ditolak, screenshot lama gagal.

5.2 Simpan ganda dan auto alpa
* Tugas: tulis attendance di HP guru, my_proof di HP siswa, auto alpa H+30 di HP admin.
* DoD: 50 pindai uji di atas 95 persen sukses.

5.3 Setoran absen beda HP dan CSV
* Tugas: ekspor setoran, import admin, rekap H I S A, CSV BOM.
* DoD: CSV benar di Excel HP dan laptop.

## FASE 6: Materi Tugas Kuis Lokal (Hari 18 sampai 22)

6.1 Materi file lokal dan kelola 500 MB
* Tugas: picker 25 MB, simpan hash, tandai penting, hapus per mapel, revisi label.
* DoD: mode pesawat tetap buka.

6.2 Tugas kumpul lokal dan setoran
* Tugas: buat tugas, kumpul 10 MB, nilai, label Terlambat plus potongan, paket setoran tugas.
* DoD: kumpul ulang menimpa benar.

6.3 Kuis PG lokal
* Tugas: bank soal, acak, 1 resmi plus 1 latihan dengan kode izin, nilai otomatis.
* DoD: 100 percobaan konsisten.

## FASE 7: Billing Pengumuman Sync Paket (Hari 23 sampai 27)

7.1 Tagihan massal lokal
* Tugas: buat massal, cegah dobel student plus period, rekening owner only.
* DoD: 100 tagihan tanpa dobel.

7.2 Bukti lokal dan kwitansi PDF
* Tugas: foto bukti, kompres 2 MB, status menunggu, review setuju dan tolak, PDF LUNAS ke Download.
* DoD: angka sama di admin dan siswa.

7.3 Distribusi paket dan pengumuman
* Tugas: ekspor distribusi (jadwal, materi metadata, pengumuman, tagihan), import dengan ringkasan dan konflik manual, pengumuman H-3 bayar otomatis lokal.
* DoD: import 200 sesi tanpa duplikat, 2 konflik uji tampil dialog benar.

7.4 Backup restore
* Tugas: ZIP terenkripsi PIN owner, simpan Download, restore timpa dengan konfirmasi, reschedule alarm.
* DoD: 10 kali backup restore sukses 100 persen.

## FASE 8: Kualitas Beta Rilis (Hari 28 sampai 32)

8.1 Uji penuh
* Tugas: 40 unit plus 15 widget hijau, audit start di bawah 3 detik, AAB di bawah 30 MB, audit string 0 temuan.
* DoD: semua hijau.

8.2 Keamanan lokal dan hapus total
* Tugas: scan secret, pastikan tidak ada kunci di repo, uji lupa PIN via owner, uji hapus total.
* DoD: secret bersih, hapus total benar benar menghapus DB, files, secure storage, alarm.

8.3 Beta 7 hari full offline
* Peserta: 10 siswa, 3 guru (min 2 perempuan), 1 admin, 2 ortu. Sebagian mode HP bersama, sebagian beda HP via paket.
* Tugas harian: alarm, verifikasi, absen, materi, bayar, sync paket.
* Metrik: crash free di atas 99.2 persen, 0 telat tanpa alarm, 0 guru pending bisa mengajar, import sukses di atas 98 persen, backup sukses 100 persen.
* DoD: laporan 1 halaman plus bug fixed.

8.4 Rilis V.01.0 local
* Tugas: version 1.0.0+1, changelog lugas, ikon final, build AAB dan APK offline untuk sideload, panduan instal tanpa Play Store, panduan rollback biner.
* DoD: checklist Bagian 14 centang semua.

---

# 14. Checklist Rilis Lokal (Wajib Centang Semua)

1. 5 tab jalan 7 hari tanpa crash kritis.
2. Alarm H-30 dan H-10 tepat toleransi 1 menit di 3 HP.
3. Tidak ada alarm hantu setelah batal, ubah, restore, import.
4. 0 sesi aktif dengan guru PENDING. Buktikan via query lokal.
5. QR basi ditolak. PIN dibatasi. Paket palsu ditolak.
6. Billing dari buat sampai kwitansi lolos di HP sama dan beda HP via paket.
7. Distribusi 200 sesi import tanpa duplikat. Konflik tampil dialog benar.
8. Backup dan restore 10 kali sukses termasuk foto dan alarm.
9. CSV dan PDF terbuka benar di HP dan laptop.
10. Start dingin di bawah 3 detik. AAB di bawah 30 MB.
11. 0 karakter U+2014 dan U+2013 di strings.
12. Tidak ada kunci API di repo. Kunci les hanya di secure storage dan QR pairing.
13. Log audit 50 terbaru tampil dan bisa diekspor.
14. Kartu PIN owner fisik sudah dicetak dan disimpan.
15. SOP 1 halaman sudah diserahkan ke admin.

Rollback lokal:
* Jika build baru gagal, instal ulang APK stabil sebelumnya lalu Restore dari ZIP terakhir. Data setelah backup terakhir perlu input ulang manual. Tulis ini jujur di panduan.

---

# 15. SOP Operasional Lokal untuk Admin

Harian 10 menit di HP les:
1. Buka Dashboard. Cek sesi hari ini, guru pending, tunggakan.
2. Review guru dan bayar yang waiting.
3. Pastikan HP dicas dan suara aktif untuk Tes Alarm mingguan.

Mingguan 30 menit:
1. Ekspor Distribusi mingguan dan kirim ke grup WA siswa yang punya HP sendiri.
2. Import semua Setoran (absen, tugas, bayar) dari siswa.
3. Ekspor CSV absensi dan simpan ke laptop.
4. Backup Full ZIP ke laptop atau flashdisk. Hapus backup lama kecuali 2 terbaru di HP.

Bulanan:
1. Buat tagihan tanggal 1. Buat pengumuman jatuh tempo.
2. Rekap H I S A per siswa untuk ortu. Cetak atau kirim sebagai PDF.
3. Cek penyimpanan. Arsip materi lama. Hapus dokumen identitas yang sudah lewat 90 hari jika memenuhi syarat.
4. Uji restore 1 kali di HP cadangan jika ada.

Kalimat baku:
* Foto ditolak: Foto belum memenuhi ketentuan. Mohon unggah ulang dengan jilbab menutup rambut di cahaya terang.
* Bayar ditolak: Bukti tidak terbaca. Mohon foto ulang struk dengan nominal dan tanggal jelas.
* Paket rusak: File tidak valid atau tidak lengkap. Minta kirim ulang file asli dari pengirim.
* Backup: Backup terakhir [tanggal]. Simpan file ZIP ini di laptop agar aman jika HP hilang.

---

# 16. Risiko Lokal dan Mitigasi

R1. HP hilang atau rusak. Dampak sangat tinggi. Mitigasi: backup ZIP mingguan wajib, kartu PIN owner fisik, 2 backup di 2 media. Pemilik: owner.
R2. Lupa PIN owner. Dampak sangat tinggi. Mitigasi: kartu fisik di amplop, tidak ada reset cloud. Tulis risiko ini di setup agar jelas.
R3. Paket paket membingungkan pengguna awam. Dampak sedang. Mitigasi: nama file baku dengan tanggal, ringkasan import jelas, konflik manual dengan bahasa sederhana.
R4. Kunci les bocor via screenshot QR. Dampak tinggi. Mitigasi: pairing hanya tatap muka, QR sekali tampil dengan timer 60 detik, log pairing.
R5. Penyimpanan penuh foto dan PDF. Dampak sedang. Mitigasi: batas 500 MB, layar kelola, kompres otomatis.
R6. Jam device salah sebabkan alarm meleset. Dampak sedang. Mitigasi: simpan UTC, tampilkan WIB, resync saat buka, peringatan jika jam manual menyimpang.
R7. Vendor matikan alarm. Dampak tinggi. Mitigasi: panduan baterai, fallback inexact, label jujur.
R8. Salah profil di HP bersama catat absen orang lain. Dampak sedang. Mitigasi: ProfileBar warna peran, konfirmasi nama sebelum simpan absen dan nilai.
R9. Copy melanggar karakter. Dampak rendah tapi fatal merek. Mitigasi: lint plus reviewer bahasa.
R10. Scope merambat minta sync otomatis cloud. Dampak sedang. Mitigasi: tolak di V.01.0, catat untuk V.02.0 server opsional.

---

# 17. Roadmap Setelah V.01.0 Lokal

V.01.1 lokal:
* Mode gelap benar, biometrik buka profil opsional, PDF rekap bulanan ortu, perbaikan OEM dari log missed.
* Paket delta: hanya kirim yang berubah agar hemat kuota WA.

V.02.0 opsional server (tidak wajib):
* Tambah sync server sebagai opsi, bukan pengganti. Repository interface sudah siap. Lokal tetap jalan jika server mati.
* QRIS tetap manual dulu, lalu gateway jika les siap.
* Web baca saja untuk owner dari hasil ekspor, bukan DB live.
* iOS TestFlight dengan Swift untuk alarm, kontrak channel sama.

Yang tetap dilarang sampai persetujuan tertulis:
* Penilaian jilbab otomatis AI.
* Chat bebas tanpa moderasi.
* Iklan pihak ketiga.

---

# 18. Lampiran Siap Pakai Lokal

## A. Lint Teks

```dart
// tools/forbid_scan.dart
// Tolak U+2014 dan U+2013 di lib, android, assets strings
import 'dart:io';
void main() {
  final roots = ['lib', 'android/app/src/main', 'assets/strings'];
  final bad = RegExp('[\u2014\u2013]');
  var found = false;
  for (final r in roots) {
    final dir = Directory(r);
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync(recursive: true)) {
      if (f is! File) continue;
      if (!f.path.endsWith('.dart') && !f.path.endsWith('.kt') && !f.path.endsWith('.xml') && !f.path.endsWith('.json') && !f.path.endsWith('.arb')) continue;
      final t = f.readAsStringSync();
      if (bad.hasMatch(t)) {
        print('FORBIDDEN CHAR in ${f.path}');
        found = true;
      }
    }
  }
  if (found) exit(1);
  print('text lint OK');
}
```

## B. Template Tiket

```
Judul: [Fase 5.1] QR HMAC lokal
Tujuan: ...
Langkah: 1... 2...
Output: ...
DoD: ...
Uji: ...
Risiko: ...
```

Tanpa DoD, tiket tidak boleh tutup.

## C. Query Audit Lokal (Drift atau SQL langsung)

```sql
-- 0 baris sebelum rilis: sesi aktif dengan guru P belum ACTIVE
SELECT s.id, s.start_utc, p.name
FROM sessions s
JOIN profiles p ON p.id = s.teacher_id
LEFT JOIN teacher_verifications v ON v.teacher_id = p.id AND v.status = 'ACTIVE'
WHERE s.status IN ('scheduled','ongoing')
AND p.role = 'GURU' AND p.gender = 'P'
AND v.id IS NULL;
```

## D. Contoh Manifest Paket

```json
{
  "v": 1,
  "kind": "distribusi",
  "from_device": "A1B2",
  "created_utc": "2026-10-12T02:00:00Z",
  "counts": {"sessions": 42, "materials": 10},
  "sha256_data": "ganti_dengan_hash",
  "sig": "ganti_dengan_hmac"
}
```

## E. Strings Terpusat

```
assets/strings/id.arb
  home_next_lesson: Les Berikutnya
  alarm_set_success: Alarm aktif untuk {subject}, {day} {time}. Kamu akan diingatkan H-30 dan H-10.
  compliance_check: Saya hadir dengan busana sesuai ketentuan, berjilbab rapi dan menutup rambut.
  sync_success: Paket diterima: {n} sesi diperbarui. Alarm ikut disesuaikan.
  backup_reminder: Backup terakhir {date}. Simpan ZIP di laptop agar aman.
```

---

# 19. Keputusan yang Butuh Kunci Kamu Sekarang

1. Pola utama: A satu HP bersama saja atau B banyak HP via paket sejak hari pertama. Rekomendasi: mulai A, aktifkan B pada Fase 7.
2. Nama paket Android: usulan `id.jogoloyo.les`. Kunci sekarang.
3. Nominal SPP dan rekening resmi untuk isi awal billing lokal.
4. Daftar mapel, level, ruang baku agar Fase 2 tidak rework.
5. Siapa owner dan siapa 2 admin, plus siapa simpan kartu PIN fisik dan flashdisk backup.

Jika 5 hal di atas dikunci, Fase 0 lokal bisa mulai langsung tanpa rework besar.

---
*Akhir plan V.01.0-local.1. Tanpa server, semua fitur jalan lokal, siap dieksekusi menjadi kode.*
