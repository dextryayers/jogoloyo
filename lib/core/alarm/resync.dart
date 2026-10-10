// Resync alarm 14 hari ke depan dari DB lokal. Anti alarm hantu.
// Dipanggil saat app dibuka, setelah import paket, setelah restore, setelah ubah jadwal.
// Aturan: sesi batal atau lewat -> cancel. Sesi aktif + enabled -> schedule ulang.
import 'package:drift/drift.dart';
import 'alarm_service.dart';
import '../../data/local/app_db.dart';
import '../../features/schedule/alarm_prefs.dart';

class AlarmResync {
  final AppDb db;
  final AlarmService alarm;
  AlarmResync(this.db, this.alarm);

  Future<({int scheduled, int cancelled})> run({String profileId = 'siswa-sinta'}) async {
    final now = DateTime.now().toUtc();
    final to = now.add(const Duration(days: 14));
    final list = await (db.select(db.sessions)
          ..where((t) => t.startUtc.isBiggerOrEqualValue(now.subtract(const Duration(hours: 6))) & t.startUtc.isSmallerThanValue(to)))
        .get();
    var sch = 0;
    var can = 0;
    for (final s in list) {
      if (s.status == 'cancelled' || s.endUtc.isBefore(now)) {
        await alarm.cancel(s.id, profileId);
        can++;
        continue;
      }
      final pref = await AlarmPrefs.load(s.id, profileId);
      if (!pref.enabled) {
        await alarm.cancel(s.id, profileId);
        can++;
        continue;
      }
      final ok = await alarm.schedule(
        sessionId: s.id,
        profileId: profileId,
        startUtc: s.startUtc,
        offsets: pref.offsets,
        title: s.subject,
        room: s.room,
        sound: pref.sound,
        loud: pref.loud,
      );
      if (ok) sch++;
    }
    return (scheduled: sch, cancelled: can);
  }
}
