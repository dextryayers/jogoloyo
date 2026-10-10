// Repo sesi lokal Drift. Cegah bentrok guru dan ruang di kode.
// Overlap [start, end). Batal butuh alasan min 10 karakter. Revisi naik tiap ubah.
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_db.dart';
import 'session_repo.dart';

class SessionLocalRepo {
  final AppDb db;
  SessionLocalRepo(this.db);

  Future<List<Session>> listWeek(DateTime weekStartUtc) async {
    final end = weekStartUtc.add(const Duration(days: 7));
    return (db.select(db.sessions)
          ..where((t) => t.startUtc.isBiggerOrEqualValue(weekStartUtc) & t.startUtc.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.startUtc)]))
        .get();
  }

  Future<List<Session>> listRange(DateTime from, DateTime to) async {
    return (db.select(db.sessions)
          ..where((t) => t.startUtc.isBiggerOrEqualValue(from) & t.startUtc.isSmallerThanValue(to))
          ..orderBy([(t) => OrderingTerm(expression: t.startUtc)]))
        .get();
  }

  Future<Session?> byId(String id) =>
      (db.select(db.sessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> create({
    required String subject,
    required String teacherId,
    required DateTime startUtc,
    required DateTime endUtc,
    required String room,
    String note = '',
  }) async {
    final all = await (db.select(db.sessions)
          ..where((t) => t.status.isIn(['scheduled', 'ongoing'])))
        .get();
    final cand = SessionInput(
      id: 'new',
      subject: subject,
      teacherId: teacherId,
      startUtc: startUtc,
      endUtc: endUtc,
      room: room,
    );
    SessionValidator.checkNoOverlap(
      cand,
      all
          .map((e) => SessionInput(
                id: e.id,
                subject: e.subject,
                teacherId: e.teacherId,
                startUtc: e.startUtc,
                endUtc: e.endUtc,
                room: e.room,
              ))
          .toList(),
    );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: const Uuid().v4(),
            subject: subject.trim(),
            teacherId: teacherId,
            startUtc: startUtc.toUtc(),
            endUtc: endUtc.toUtc(),
            room: room,
            note: Value(note.trim()),
          ),
        );
  }

  Future<void> updateTime({
    required String id,
    required DateTime startUtc,
    required DateTime endUtc,
    String? room,
  }) async {
    final cur = await byId(id);
    if (cur == null) throw Exception('Sesi tidak ditemukan.');
    final all = await (db.select(db.sessions)
          ..where((t) => t.status.isIn(['scheduled', 'ongoing'])))
        .get();
    final cand = SessionInput(
      id: id,
      subject: cur.subject,
      teacherId: cur.teacherId,
      startUtc: startUtc,
      endUtc: endUtc,
      room: room ?? cur.room,
    );
    SessionValidator.checkNoOverlap(
      cand,
      all
          .where((e) => e.id != id)
          .map((e) => SessionInput(
                id: e.id,
                subject: e.subject,
                teacherId: e.teacherId,
                startUtc: e.startUtc,
                endUtc: e.endUtc,
                room: e.room,
              ))
          .toList(),
    );
    await (db.update(db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        startUtc: Value(startUtc.toUtc()),
        endUtc: Value(endUtc.toUtc()),
        room: room == null ? const Value.absent() : Value(room),
        revision: Value(cur.revision + 1),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> cancel({required String id, required String reason}) async {
    if (reason.trim().length < 10) {
      throw Exception('Alasan batal min 10 karakter. Tulis jelas agar siswa paham.');
    }
    await (db.update(db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        status: const Value('cancelled'),
        note: Value('Batal: ${reason.trim()}'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
