// F5.3 Ekspor CSV absensi. UTF-8 BOM agar benar di Excel Indonesia.
// Header baku: tanggal, jam, mapel, guru, nama, status, metode.
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/time/wib.dart';
import '../../data/local/app_db.dart';

class ExportService {
  final AppDb db;
  ExportService(this.db);

  Future<File> attendanceCsv({String? sessionId}) async {
    final rows = <List<String>>[
      ['tanggal', 'jam', 'mapel', 'guru', 'nama', 'status', 'metode']
    ];
    final sessions = sessionId == null
        ? await (db.select(db.sessions)).get()
        : [await (db.select(db.sessions)..where((t) => t.id.equals(sessionId))).getSingle()];
    for (final s in sessions) {
      final atts = await (db.select(db.attendances)..where((t) => t.sessionId.equals(s.id))).get();
      for (final a in atts) {
        final prof = await (db.select(db.profiles)..where((t) => t.id.equals(a.profileId))).getSingleOrNull();
        final guru = await (db.select(db.profiles)..where((t) => t.id.equals(s.teacherId))).getSingleOrNull();
        rows.add([
          Wib.dmy(s.startUtc),
          Wib.range(s.startUtc, s.endUtc),
          s.subject,
          guru?.name ?? s.teacherId,
          prof?.name ?? a.profileId,
          a.status,
          a.method,
        ]);
      }
    }
    final csv = const ListToCsvConverter().convert(rows);
    // Escape koma dan petik sudah ditangani converter. Tambah BOM.
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/absensi_jogoloyo_${DateTime.now().toUtc().millisecondsSinceEpoch}.csv');
    await f.writeAsString('\uFEFF$csv');
    return f;
  }

  Future<void> share(File f) =>
      SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: 'Rekap absensi Les Jogoloyo'));
}
