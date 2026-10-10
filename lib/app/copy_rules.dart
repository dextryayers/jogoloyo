// Aturan copywriting baku. Semua teks layar baru wajib tambah di sini dulu.
// Larangan: karakter U+2014 dan U+2013, emoji di area formal, headline kosong.
class CopyRules {
  static const appName = 'Les Jogoloyo';
  static const version = 'V.01.0 local';
  static const packageName = 'id.jogoloyo.les';

  static const homeNext = 'Les Berikutnya';
  static const homeEmpty = 'Belum ada jadwal minggu ini. Hubungi admin jika ini keliru.';
  static const scheduleTitle = 'Jadwal Les';
  static const teacherTitle = 'Guru Jogoloyo';
  static const materialTitle = 'Materi dan Tugas';
  static const profileTitle = 'Akun Saya';

  static const setAlarm = 'Atur Alarm';
  static const testAlarm = 'Tes Alarm';
  static const otw = 'Saya OTW';
  static const atLocation = 'Saya Sudah di Lokasi';
  static const scanPresent = 'Pindai untuk Hadir';
  static const uploadProof = 'Unggah Bukti';

  static const qrExpired = 'Kode kedaluwarsa. Minta kode baru ke guru.';
  static const compliance =
      'Saya hadir dengan busana sesuai ketentuan, berjilbab rapi dan menutup rambut.';

  static String alarmActive(String subject, String day, String time) =>
      'Alarm aktif untuk $subject, $day $time. Kamu akan diingatkan H-30 dan H-10.';

  // Daftar kata generik yang ditolak di review bahasa.
  static const bannedWords = [
    'delve',
    'unlock',
    'elevate',
    'game changer',
    'revolutionize',
    'supercharge',
  ];
}
