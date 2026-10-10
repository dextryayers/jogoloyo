// Util waktu WIB. Simpan UTC, tampil WIB dengan label eksplisit.
// Format baku: jam 15.30 WIB, tanggal Senin, 13 Okt 2026.
import 'package:intl/intl.dart';

class Wib {
  static final _hm = DateFormat('HH.mm');
  static final _dmy = DateFormat('EEE, d MMM yyyy', 'id');

  // UTC ke label jam WIB.
  static String hm(DateTime utc) {
    final wib = utc.toUtc().add(const Duration(hours: 7));
    return '${_hm.format(wib)} WIB';
  }

  // UTC ke label tanggal WIB.
  static String dmy(DateTime utc) {
    final wib = utc.toUtc().add(const Duration(hours: 7));
    return _dmy.format(wib);
  }

  // Rentang sesi: 15.30 - 17.00 WIB. Pakai hubung biasa, bukan karakter khusus.
  static String range(DateTime startUtc, DateTime endUtc) {
    final a = startUtc.toUtc().add(const Duration(hours: 7));
    final b = endUtc.toUtc().add(const Duration(hours: 7));
    return '${_hm.format(a)} - ${_hm.format(b)} WIB';
  }

  // Cek overlap interval [aStart, aEnd) dengan [bStart, bEnd).
  static bool overlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }
}
