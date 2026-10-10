// Uji model pengingat murni: roundtrip plus baca format lama.
// Tanpa HP, tanpa database.
import 'package:flutter_test/flutter_test.dart';
import 'package:jogoloyo_les/data/local/simple_store.dart';

void main() {
  test('roundtrip simpan baca sama persis', () {
    final r = Reminder(
      id: 'a1',
      title: 'Minum obat',
      whenUtc: DateTime.utc(2026, 10, 12, 23, 0),
      sound: 'suara3',
      level: 175,
      vibrate: false,
      enabled: true,
      daily: true,
    );
    final back = Reminder.fromJson(r.toJson());
    expect(back.id, 'a1');
    expect(back.title, 'Minum obat');
    expect(back.whenUtc, DateTime.utc(2026, 10, 12, 23, 0));
    expect(back.sound, 'suara3');
    expect(back.level, 175);
    expect(back.vibrate, false);
    expect(back.daily, true);
  });

  test('format lama loud dibaca jadi level', () {
    final back = Reminder.fromJson({
      'id': 'b2',
      'title': 'Lama',
      'iso': DateTime.utc(2026, 10, 12).toIso8601String(),
      'sound': 'suara2',
      'loud': false,
    });
    expect(back.level, 100);
    expect(back.vibrate, true);
  });

  test('wib format jam dan hari benar', () {
    expect(wibHm(DateTime.utc(2026, 10, 12, 23, 30)), '06:30');
    expect(wibDay(DateTime.utc(2026, 10, 12, 23, 30)), 'Sel, 13/10');
  });
}
