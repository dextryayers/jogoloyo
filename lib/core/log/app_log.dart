// Log lokal ringan F8: 100 baris terakhir di memori plus file diagnosis.
// Tanpa kirim ke server. Untuk lampiran bug beta via Share.
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLog {
  static final List<String> _mem = [];

  static void record(String event, String detail) {
    final line = '${DateTime.now().toUtc().toIso8601String()} $event $detail';
    _mem.add(line);
    if (_mem.length > 100) _mem.removeAt(0);
  }

  static List<String> recent() => List.unmodifiable(_mem);

  static Future<File> dumpFile() async {
    final tmp = await getTemporaryDirectory();
    final f = File('${tmp.path}/jogoloyo_log_${DateTime.now().toUtc().millisecondsSinceEpoch}.txt');
    await f.writeAsString(_mem.join('\n'));
    return f;
  }
}
