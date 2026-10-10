// Seed lokal untuk HP baru dan beta. Id stabil agar tidak duplikat saat import ulang.
// Guru demo: Rina Matematika, Dewi Biologi. 6 sesi minggu ini di Ruang A dan B.
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/security/pin_hash.dart';
import 'app_db.dart';

Future<void> seedIfEmpty(AppDb db, FlutterSecureStorage secure) async {
  final n = await (db.selectOnly(db.profiles)..addColumns([db.profiles.id.count()])).getSingle();
  final count = n.read(db.profiles.id.count()) ?? 0;
  if (count > 0) return;

  String pin(String v) {
    final salt = PinHash.makeSalt();
    return '$salt::${PinHash.hash(v, salt)}';
  }

  Future<void> addProfile(String id, String role, String name, String? gender) async {
    final parts = pin('123456').split('::');
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: id,
            role: role,
            name: name,
            pinHash: parts[1],
            salt: parts[0],
            gender: Value(gender),
          ),
        );
  }

  await addProfile('guru-rina', 'GURU', 'Ustazah Rina', 'P');
  await addProfile('guru-dewi', 'GURU', 'Ustazah Dewi', 'P');
  await addProfile('siswa-sinta', 'SISWA', 'Sinta', null);
  await addProfile('admin-budi', 'ADMIN', 'Pak Budi', null);

  await db.into(db.teacherVerifs).insert(
        TeacherVerifsCompanion.insert(
          id: 'ver-rina',
          teacherId: 'guru-rina',
          photoPath: '',
          idDocPath: '',
          status: const Value('ACTIVE'),
          reviewerId: const Value('admin-budi'),
        ),
      );
  await db.into(db.teacherVerifs).insert(
        TeacherVerifsCompanion.insert(
          id: 'ver-dewi',
          teacherId: 'guru-dewi',
          photoPath: '',
          idDocPath: '',
          status: const Value('ACTIVE'),
          reviewerId: const Value('admin-budi'),
        ),
      );

  final base = DateTime.utc(2026, 10, 12, 8, 30);
  final rows = [
    ('sess-001', 'Matematika kelas 8', 'guru-rina', 0, 'Ruang A', 'Bawa buku latihan bab 3'),
    ('sess-002', 'Biologi kelas 9', 'guru-dewi', 1, 'Ruang B', 'Siapkan gambar sel'),
    ('sess-003', 'Matematika kelas 8', 'guru-rina', 2, 'Ruang A', 'Kuis 10 soal'),
    ('sess-004', 'Fisika kelas 8', 'guru-rina', 4, 'Ruang A', 'Bawa kalkulator'),
    ('sess-005', 'Biologi kelas 9', 'guru-dewi', 5, 'Ruang B', 'Praktik ringan'),
    ('sess-006', 'Matematika kelas 8', 'guru-rina', 6, 'Ruang A', 'Remidi bab 3'),
  ];
  for (final r in rows) {
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: r.$1,
            subject: r.$2,
            teacherId: r.$3,
            startUtc: base.add(Duration(days: r.$4)),
            endUtc: base.add(Duration(days: r.$4, minutes: 90)),
            room: r.$5,
            note: Value(r.$6),
          ),
        );
  }
}
