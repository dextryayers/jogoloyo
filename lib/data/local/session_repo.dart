// Repository interface agar UI tidak tergantung Drift langsung.
// Siap migrasi ke server nanti tanpa ubah UI. V.01.0 impl lokal saja.
import '../../core/time/wib.dart';

class SessionInput {
  final String id;
  final String subject;
  final String teacherId;
  final DateTime startUtc;
  final DateTime endUtc;
  final String room;
  final String note;
  const SessionInput({
    required this.id,
    required this.subject,
    required this.teacherId,
    required this.startUtc,
    required this.endUtc,
    required this.room,
    this.note = '',
  });
}

abstract class SessionRepo {
  Future<void> create(SessionInput s);
  Future<List<SessionInput>> list(DateTime fromUtc, DateTime toUtc);
}

class OverlapError implements Exception {
  final String message;
  OverlapError(this.message);
  @override
  String toString() => message;
}

// Validasi murni, bisa diunit test tanpa DB.
class SessionValidator {
  static void checkNoOverlap(SessionInput candidate, List<SessionInput> active) {
    for (final s in active) {
      if (s.id == candidate.id) continue;
      final sameTeacher = s.teacherId == candidate.teacherId;
      final sameRoom = s.room == candidate.room;
      if (!sameTeacher && !sameRoom) continue;
      if (Wib.overlap(s.startUtc, s.endUtc, candidate.startUtc, candidate.endUtc)) {
        if (sameTeacher) {
          throw OverlapError('Guru sudah mengajar pada jam itu di ${s.subject}.');
        }
        throw OverlapError('Ruang ${s.room} dipakai pada jam itu oleh ${s.subject}.');
      }
    }
    if (!candidate.endUtc.isAfter(candidate.startUtc)) {
      throw OverlapError('Jam selesai harus setelah jam mulai.');
    }
  }
}
