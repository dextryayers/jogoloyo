// F5.2 Repo absensi lokal. Tulis hadir via QR atau PIN, batas 5 salah per sesi.
// Auto alpa H+30 untuk sesi lewat tanpa catatan. Rekap per sesi dan per siswa.
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_db.dart';

class AttendanceError implements Exception {
  final String message;
  AttendanceError(this.message);
  @override
  String toString() => message;
}

class AttendanceRepo {
  final AppDb db;
  AttendanceRepo(this.db);

  Future<void> markPresent({
    required String sessionId,
    required String profileId,
    String method = 'qr',
  }) async {
    final ex = await (db.select(db.attendances)
          ..where((t) => t.sessionId.equals(sessionId) & t.profileId.equals(profileId)))
        .getSingleOrNull();
    if (ex != null) {
      await (db.update(db.attendances)..where((t) => t.id.equals(ex.id))).write(
        AttendancesCompanion(status: const Value('hadir'), method: Value(method)),
      );
      return;
    }
    await db.into(db.attendances).insert(
          AttendancesCompanion.insert(
            sessionId: sessionId,
            profileId: profileId,
            status: 'hadir',
            method: Value(method),
          ),
        );
  }

  Future<void> notePinFail(String sessionId, String profileId) async {
    final p = await SharedPreferences.getInstance();
    final k = 'pin_fail_${sessionId}_$profileId';
    final n = (p.getInt(k) ?? 0) + 1;
    await p.setInt(k, n);
    if (n >= 5) throw AttendanceError('Terlalu banyak salah. Minta QR baru ke guru.');
  }

  Future<void> clearPinFail(String sessionId, String profileId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('pin_fail_${sessionId}_$profileId');
  }

  Future<int> autoAlpa() async {
    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(const Duration(minutes: 30));
    final done = await (db.select(db.sessions)
          ..where((t) => t.endUtc.isSmallerThanValue(cutoff) & t.status.equals('scheduled')))
        .get();
    var n = 0;
    for (final s in done) {
      final has = await (db.select(db.attendances)..where((t) => t.sessionId.equals(s.id))).get();
      if (has.isEmpty) {
        await db.into(db.attendances).insert(
              AttendancesCompanion.insert(
                sessionId: s.id,
                profileId: 'siswa-sinta',
                status: 'alpa',
                method: const Value('auto_alpa'),
              ),
            );
        n++;
      }
      await (db.update(db.sessions)..where((t) => t.id.equals(s.id)))
          .write(const SessionsCompanion(status: Value('done')));
    }
    return n;
  }

  Future<List<Attendance>> bySession(String sessionId) =>
      (db.select(db.attendances)..where((t) => t.sessionId.equals(sessionId))).get();

  Future<Map<String, int>> recapMonth(String profileId, int year, int month) async {
    final all = await (db.select(db.attendances)..where((t) => t.profileId.equals(profileId))).get();
    final m = {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0};
    for (final a in all) {
      if (a.createdAt.year == year && a.createdAt.month == month && m.containsKey(a.status)) {
        m[a.status] = m[a.status]! + 1;
      }
    }
    return m;
  }
}
