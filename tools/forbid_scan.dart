// Pemindai karakter terlarang untuk Les Jogoloyo V.01.0 local.
// Menolak U+2014 dan U+2013 di lib, android/app/src/main, assets/strings.
// Cara pakai: dart run tools/forbid_scan.dart
// Keluar 1 jika ada temuan, 0 jika bersih.
import 'dart:io';

void main() {
  final roots = ['lib', 'android/app/src/main', 'assets/strings'];
  final bad = RegExp('[\u2014\u2013]');
  var found = false;
  var checked = 0;
  for (final r in roots) {
    final dir = Directory(r);
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync(recursive: true)) {
      if (f is! File) continue;
      final p = f.path;
      if (!(p.endsWith('.dart') ||
          p.endsWith('.kt') ||
          p.endsWith('.xml') ||
          p.endsWith('.json') ||
          p.endsWith('.arb') ||
          p.endsWith('.gradle.kts'))) {
        continue;
      }
      checked++;
      final t = f.readAsStringSync();
      if (bad.hasMatch(t)) {
        stdout.writeln('FORBIDDEN CHAR di $p');
        found = true;
      }
    }
  }
  if (found) {
    stderr.writeln('Gagal: ada karakter terlarang. Pakai - atau : atau , sebagai ganti.');
    exit(1);
  }
  stdout.writeln('text lint OK. $checked file diperiksa.');
}
