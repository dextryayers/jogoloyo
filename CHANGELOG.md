# Changelog Les Jogoloyo

## 1.0.0+1 - V.02 simpel ramping

- Hapus total halaman lama: jadwal, guru, absensi, materi, billing, sync, pin, wipe. Sisa 43 file Dart.
- Dependensi ramping: qr, scanner, file picker, pdf, csv, archive, open file dibuang. APK jauh lebih ringan.
- 4 tab bawah: Beranda, Catatan, Setting, Profil. Daftar pengingat halaman sendiri via shortcut.
- Dashboard plus 6 shortcut: Pengingat Baru, Daftar Pengingat, Catatan Baru, Tes Bunyi, Waktu Notifikasi, Profil Saya.
- Tab Setting: izin presisi, suara default, mode keras, tes, ubah waktu, lapor masalah plus log, reset.
- Lapor Masalah: form judul rincian, simpan lokal, bagikan plus file log ke admin.
- Kekerasan 100 125 150 175 200 persen plus boost gain native, getar bisa mati hidup per pengingat dan default.
- Setting: minta izin notifikasi sistem plus status real, play stop di semua layar suara.
- Ekspor catatan: PNG JPG JPEG plus pixel Low Normal High XHigh anti burik, PDF, simpan ke galeri.
- Getar: amplitudo maksimal 255 plus pola lebih panjang, jalur cadangan via notifikasi, status mesin getar di Setting, getar mati hidup tetap dihormati di tes dan real.
- Dashboard dua bagian Hari ini plus Mendatang agar buatan user tanggal lain tetap tampil.
- Verifikasi terpasang nyata via sistem plus lapor jujur saat simpan.
- Catatan anti hilang: autosave saat keluar tanpa tekan Simpan, tarik untuk refresh manual, buka lagi selalu muat plus tangani bila terhapus.
- Izin notifikasi otomatis: diminta sendiri tepat setelah onboarding plus sekali lagi saat masuk setup notifikasi bila masih mati.
- Tab Profil: hanya profil berfoto plus ubah profil dan waktu notifikasi. Tanpa kode PIN.
- Setting: izin notifikasi sistem bisa diminta langsung plus status real, tombol Play dan Stop untuk tes suara, status alarm presisi real.
- Notepad baru: kartu strip warna, tanggal WIB plus hitung kata, cari, geser hapus plus urungkan, FAB Tulis, editor lega dengan hitung kata live dan bar simpan.

## 1.0.0+1 - V.02 simpel

- Rombak total: hanya pengingat plus catatan. Fitur lama dihapus dari navigasi.
- Alur: loading, onboarding 3 halaman, profil (nama, foto autosave, jam Pagi Siang Sore Malam, gender), setup notifikasi (jam tiap slot, suara, mode keras), lalu dashboard.
- 4 tab bawah: Beranda, Pengingat, Catatan, Saya.
- Pengingat: judul, tanggal, jam, slot cepat, harian, Suara 1 sampai 6, Mode Keras 200 persen, tes bunyi. Bunyi otomatis plus getar via alarm exact offset 0.
- Catatan: notepad cari tambah ubah hapus.
- Saya: profil berfoto, setting sistem (izin, suara default, mode keras, tes, ubah profil, ubah waktu, reset).

## 1.0.0+1 - V.01.0 local deep + logo

- Logo resmi assets/logo.png: icon launcher Android, splash native, splash dalam app, onboarding, setup, header dashboard.
- Alur baru: splash 2 detik, onboarding 3 halaman, setup guru (nama, mapel, foto kamera autosave), lalu dashboard 5 tab bawah.
- Foto profil autosave lokal: langsung tersimpan saat diambil, tampil di bar profil dan menu Saya, bisa ganti kapan saja.
- Dashboard: header logo plus versi, sapaan nama profil aktif, Les Berikutnya nyata, alarm, OTW, tagihan, pengumuman nyata.
- Alarm Suara 1 sampai 6: pilih di form, ketuk untuk dengar langsung, otomatis bunyi plus getar tepat waktu.
- Alarm selamat reboot: data bunyi disimpan native dan didaftar ulang otomatis plus hapus sekali tembak anti dobel.
- Form waktu: default hari ini WIB, tanggal tidak bisa mundur, pesan jelas bila lewat atau mati, konfirmasi tampilkan jam, warning bila presisi mati.
- Daftar: banner jujur bila presisi mati, info level dan getar per baris, resync tiap resume dan refresh.

## 1.0.0+1 - V.01.0 local deep

- Bootstrap: binding, zona Asia/Jakarta, ErrorWidget Indonesia, log lokal 100 baris.
- Tema: input, dialog, snackbar, divider, text theme. Label app Les Jogoloyo.
- Guard startup ke setup jika tanpa owner. PIN lockout waktu 5 menit plus audit gagal.
- Tautan ortu sekali pakai dengan batas 2 ortu per anak dan 4 anak per ortu.
- Jadwal: cari mapel guru ruang, kartu izin presisi jika exact mati, resync saat resume.
- Form: prefill saat ubah, tombol Cek Bentrok Dulu dengan banner merah spesifik.
- Beranda: pengumuman nyata 3 terbaru, resync plus auto alpa otomatis, observer resume, Semantics Atur Alarm dan OTW.
- Guru: riwayat audit 5 terbaru di detail. Guard ACTIVE only tetap dijaga di repo.
- Absensi: rekap HISA bulan berjalan, auto alpa otomatis saat buka, overlay bingkai QR plus pesan izin kamera.
- Materi: buka file via open_filex, hapus tahan dengan konfirmasi, bar 500 MB plus peringatan 80 persen.
- Tugas: daftar kumpul 10 terbaru plus denda 10 persen per hari maks 30 persen.
- Kuis: timer mundur plus kumpul otomatis saat habis.
- Billing: kwitansi nomor urut JGL-periode-0001 berdasar urutan buat.
- Sync: restore ZIP dengan PIN owner plus restart, hapus total tetap ada.
- Uji: 15 lolos termasuk billing dobel, kuis 80, QR basi, paket HMAC.
