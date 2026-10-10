// F4.2 Repo verifikasi guru lokal. State machine dijaga di kode.
// DRAFT -> PENDING -> ACTIVE, PENDING -> REJECTED -> PENDING, ACTIVE -> SUSPENDED.
// Setiap transisi tulis audit. Ganti foto pasca ACTIVE kembali ke PENDING mini review.
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_db.dart';

class VerifError implements Exception {
  final String message;
  VerifError(this.message);
  @override
  String toString() => message;
}

class TeacherRepo {
  final AppDb db;
  TeacherRepo(this.db);

  static const reasons = [
    'Foto tidak jelas',
    'Rambut masih terlihat',
    'Bukan foto asli wajah',
    'Dokumen tidak terbaca',
  ];

  Future<String> submit({
    required String teacherId,
    required String photoPath,
    required String idDocPath,
  }) async {
    final cur = await (db.select(db.teacherVerifs)..where((t) => t.teacherId.equals(teacherId)))
        .getSingleOrNull();
    if (cur != null && cur.attempts >= 4) {
      throw VerifError('Batas unggah 3 kali dalam 7 hari tercapai. Hubungi admin.');
    }
    final id = cur?.id ?? const Uuid().v4();
    final from = cur?.status ?? 'DRAFT';
    if (cur == null) {
      await db.into(db.teacherVerifs).insert(
            TeacherVerifsCompanion.insert(
              id: id,
              teacherId: teacherId,
              photoPath: photoPath,
              idDocPath: idDocPath,
              status: const Value('PENDING'),
            ),
          );
    } else {
      await (db.update(db.teacherVerifs)..where((t) => t.id.equals(id))).write(
        TeacherVerifsCompanion(
          photoPath: Value(photoPath),
          idDocPath: Value(idDocPath),
          status: const Value('PENDING'),
          attempts: Value(cur.attempts + 1),
        ),
      );
    }
    await _audit(verifId: id, actorId: teacherId, from: from, to: 'PENDING', reason: 'Pengajuan');
    return id;
  }

  Future<void> review({
    required String verifId,
    required String reviewerId,
    required bool approve,
    String? reason,
  }) async {
    final v = await (db.select(db.teacherVerifs)..where((t) => t.id.equals(verifId))).getSingleOrNull();
    if (v == null) throw VerifError('Pengajuan tidak ditemukan.');
    if (approve) {
      await (db.update(db.teacherVerifs)..where((t) => t.id.equals(verifId))).write(
        TeacherVerifsCompanion(
          status: const Value('ACTIVE'),
          reviewerId: Value(reviewerId),
          reason: const Value.absent(),
        ),
      );
      await _audit(verifId: verifId, actorId: reviewerId, from: v.status, to: 'ACTIVE', reason: 'Disetujui');
    } else {
      final r = (reason ?? '').trim();
      if (r.length < 10) throw VerifError('Alasan tolak min 10 karakter agar jelas.');
      await (db.update(db.teacherVerifs)..where((t) => t.id.equals(verifId))).write(
        TeacherVerifsCompanion(
          status: const Value('REJECTED'),
          reviewerId: Value(reviewerId),
          reason: Value(r),
        ),
      );
      await _audit(verifId: verifId, actorId: reviewerId, from: v.status, to: 'REJECTED', reason: r);
    }
  }

  Future<void> suspend({
    required String teacherId,
    required String actorId,
    required String reason,
  }) async {
    final v = await (db.select(db.teacherVerifs)..where((t) => t.teacherId.equals(teacherId))).getSingleOrNull();
    if (v == null) throw VerifError('Guru belum pernah mengajukan.');
    final r = reason.trim();
    if (r.length < 10) throw VerifError('Alasan suspend min 10 karakter.');
    await (db.update(db.teacherVerifs)..where((t) => t.id.equals(v.id))).write(
      TeacherVerifsCompanion(status: const Value('SUSPENDED'), reason: Value(r)),
    );
    await _audit(verifId: v.id, actorId: actorId, from: v.status, to: 'SUSPENDED', reason: r);
  }

  Future<void> checkin({
    required String sessionId,
    required String teacherId,
    required bool compliance,
  }) async {
    if (!compliance) throw VerifError('Centang pernyataan kepatuhan dulu agar bisa check in.');
    await db.into(db.checkins).insert(
          CheckinsCompanion.insert(
            sessionId: sessionId,
            teacherId: teacherId,
            compliance: Value(compliance),
          ),
        );
  }

  Future<List<TeacherVerif>> pending() =>
      (db.select(db.teacherVerifs)..where((t) => t.status.equals('PENDING'))..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  Future<TeacherVerif?> byTeacher(String teacherId) =>
      (db.select(db.teacherVerifs)..where((t) => t.teacherId.equals(teacherId))).getSingleOrNull();

  Future<bool> isActive(String teacherId) async {
    final v = await byTeacher(teacherId);
    return v?.status == 'ACTIVE';
  }

  Future<void> _audit({
    required String verifId,
    required String actorId,
    required String? from,
    required String to,
    required String? reason,
  }) async {
    await db.into(db.verifAudits).insert(
          VerifAuditsCompanion.insert(
            id: const Uuid().v4(),
            verifId: verifId,
            actorId: actorId,
            fromStatus: Value(from),
            toStatus: to,
            reason: Value(reason),
          ),
        );
  }
}
