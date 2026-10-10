// Uji label presisi alarm dan aturan anti hantu.
// Tanpa HP, logika murni.
import 'package:flutter_test/flutter_test.dart';
import 'package:jogoloyo_les/features/schedule/alarm_prefs.dart';

void main() {
  test('label presisi jujur', () {
    expect(AlarmPrefs.precisionLabel(exactGranted: true, enabled: true), 'Presisi');
    expect(AlarmPrefs.precisionLabel(exactGranted: false, enabled: true), 'Tidak presisi');
    expect(AlarmPrefs.precisionLabel(exactGranted: true, enabled: false), 'Mati');
  });

  test('kunci alarm unik per sesi plus profil plus offset', () {
    final a = AlarmPrefs.key('sess1', 'sinta');
    final b = AlarmPrefs.key('sess1', 'rina');
    final c = AlarmPrefs.key('sess2', 'sinta');
    expect(a == b, false);
    expect(a == c, false);
  });
}
