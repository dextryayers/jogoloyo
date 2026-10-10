// F7.3 Backup ZIP lokal plus sync paket distribusi.
// Backup: salin jogoloyo.db plus folder teacher_photos, materi, tugas ke ZIP.
// Restore: validasi PIN owner via hash, timpa, lalu reschedule alarm oleh pemanggil.
// Distribusi: ekspor sessions 200 terbaru plus materials metadata plus announcements ke JSON.
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/security/pin_hash.dart';
import 'app_db.dart';

class BackupService {
  final AppDb db;
  BackupService(this.db);

  Future<File> backupNow() async {
    final docs = await getApplicationDocumentsDirectory();
    final tmp = await getTemporaryDirectory();
    final out = File(p.join(tmp.path, 'jogoloyo_backup_${DateTime.now().toUtc().millisecondsSinceEpoch}.zip'));
    final enc = ZipFileEncoder()..create(out.path);
    final dbFile = File(p.join(docs.path, 'jogoloyo.db'));
    if (await dbFile.exists()) enc.addFile(dbFile, 'jogoloyo.db');
    for (final d in ['teacher_photos', 'materi', 'tugas']) {
      final dir = Directory(p.join(docs.path, d));
      if (await dir.exists()) {
        await for (final f in dir.list(recursive: true)) {
          if (f is File) enc.addFile(f, p.join(d, p.basename(f.path)));
        }
      }
    }
    final sessions = await (db.select(db.sessions)).get();
    enc.addArchiveFile(ArchiveFile(
        'manifest.json',
        0,
        utf8.encode(jsonEncode({
          'v': 1,
          'created_utc': DateTime.now().toUtc().toIso8601String(),
          'sessions': sessions.length,
        }))));
    enc.close();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_backup', DateTime.now().toUtc().toIso8601String());
    return out;
  }

  Future<void> assertOwnerPin(String ownerId, String pin) async {
    final owner = await (db.select(db.profiles)..where((t) => t.id.equals(ownerId))).getSingleOrNull();
    if (owner == null) throw Exception('Owner tidak ditemukan.');
    if (!PinHash.verify(pin, owner.salt, owner.pinHash)) throw Exception('PIN owner salah.');
  }
}

class DistribusiService {
  final AppDb db;
  DistribusiService(this.db);

  Future<File> exportDistribusi() async {
    final sessions = await (db.select(db.sessions)).get();
    final take = sessions.length > 200 ? sessions.sublist(sessions.length - 200) : sessions;
    final mats = await (db.select(db.materials)).get();
    final anns = await (db.select(db.announcements)).get();
    final data = {
      'sessions': take.map((e) => {'id': e.id, 'subject': e.subject, 'teacherId': e.teacherId, 'startUtc': e.startUtc.toIso8601String(), 'endUtc': e.endUtc.toIso8601String(), 'room': e.room, 'note': e.note, 'status': e.status, 'revision': e.revision}).toList(),
      'materials_meta': mats.map((e) => {'id': e.id, 'subject': e.subject, 'title': e.title}).toList(),
      'announcements': anns.map((e) => {'id': e.id, 'title': e.title, 'body': e.body}).toList(),
    };
    final tmp = await getTemporaryDirectory();
    final f = File(p.join(tmp.path, 'jogoloyo_distribusi_${DateTime.now().toUtc().millisecondsSinceEpoch}.json'));
    await f.writeAsString(jsonEncode(data));
    return f;
  }

  Future<({int updated, int skipped})> importDistribusi(File f) async {
    final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final list = (m['sessions'] as List).cast<Map<String, dynamic>>();
    var updated = 0;
    var skipped = 0;
    for (final s in list) {
      final id = s['id'] as String;
      final ex = await (db.select(db.sessions)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (ex == null) {
        skipped++;
        continue;
      }
      final rev = (s['revision'] as num?)?.toInt() ?? 1;
      if (rev > ex.revision) {
        await (db.update(db.sessions)..where((t) => t.id.equals(id))).write(
          SessionsCompanion(
            subject: Value(s['subject'] as String),
            room: Value(s['room'] as String),
            status: Value(s['status'] as String),
            revision: Value(rev),
          ),
        );
        updated++;
      } else {
        skipped++;
      }
    }
    return (updated: updated, skipped: skipped);
  }
}
