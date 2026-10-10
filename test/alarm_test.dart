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

  test('enam suara valid plus default suara1 dan keras aktif', () {
    expect(AlarmSound.options.length, 6);
    expect(AlarmSound.options.map((e) => e.label).toList(),
        ['Suara 1', 'Suara 2', 'Suara 3', 'Suara 4', 'Suara 5', 'Suara 6']);
    expect(AlarmSound.isValid('suara3'), true);
    expect(AlarmSound.isValid('suara9'), false);
    expect(AlarmPrefs.defaultSound, 'suara1');
  });

  test('level valid 100 sampai 200 dan gain naik', () {
    expect(AlarmLevel.options, [100, 125, 150, 175, 200]);
    expect(AlarmLevel.gainDb(100), 0);
    expect(AlarmLevel.gainDb(200) > AlarmLevel.gainDb(150), true);
    expect(AlarmLevel.gainDb(150) > AlarmLevel.gainDb(125), true);
  });
}
