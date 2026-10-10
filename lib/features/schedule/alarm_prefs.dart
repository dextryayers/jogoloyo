// Preferensi alarm per sesi per profil. Simpan di SharedPreferences.
// Kunci: alarm_{sessionId}_{profileId}. Value: offsets|enabled|suara|level|getar.
// Contoh: 30,10|1|suara1|200|1. Format lama tetap dibaca: loud 1 jadi 200, 0 jadi 100.
// Default: 30,10 aktif, Suara 1, level 200 persen, getar aktif.
import 'package:shared_preferences/shared_preferences.dart';

class AlarmSound {
  final String id;
  final String label;
  const AlarmSound(this.id, this.label);

  static const options = [
    AlarmSound('suara1', 'Suara 1'),
    AlarmSound('suara2', 'Suara 2'),
    AlarmSound('suara3', 'Suara 3'),
    AlarmSound('suara4', 'Suara 4'),
    AlarmSound('suara5', 'Suara 5'),
    AlarmSound('suara6', 'Suara 6'),
  ];

  static bool isValid(String id) => options.any((e) => e.id == id);
}

class AlarmLevel {
  static const options = [100, 125, 150, 175, 200];

  static bool isValid(int v) => options.contains(v);

  // Level ke gain desibel untuk uji. 200 persen sekitar 6 dB.
  static double gainDb(int level) {
    if (level <= 100) return 0;
    return 20 * _log10(level / 100);
  }

  static double _log10(double x) => _ln(x) / _ln10;
  static const _ln10 = 2.302585092994046;
  static double _ln(double x) {
    var n = 0;
    while (x > 2) {
      x /= 2;
      n++;
    }
    while (x < 1) {
      x *= 2;
      n--;
    }
    var y = (x - 1) / (x + 1);
    var y2 = y * y;
    var s = y;
    var t = y;
    for (var k = 3; k <= 15; k += 2) {
      t *= y2;
      s += t / k;
    }
    return 2 * s + n * 0.6931471805599453;
  }
}

class AlarmPrefs {
  static const defaultSound = 'suara1';
  static const defaultLevel = 200;

  static String key(String sessionId, String profileId) => 'alarm_${sessionId}_$profileId';

  static Future<({List<int> offsets, bool enabled, String sound, int level, bool vibrate})> load(
    String sessionId,
    String profileId, {
    List<int> fallback = const [30, 10],
  }) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key(sessionId, profileId));
    if (raw == null) {
      return (offsets: fallback, enabled: true, sound: defaultSound, level: defaultLevel, vibrate: true);
    }
    final parts = raw.split('|');
    if (parts.length < 2) {
      return (offsets: fallback, enabled: true, sound: defaultSound, level: defaultLevel, vibrate: true);
    }
    final offs = parts[0].split(',').where((e) => e.isNotEmpty).map(int.parse).toList();
    final sound = parts.length > 2 && AlarmSound.isValid(parts[2]) ? parts[2] : defaultSound;
    var level = defaultLevel;
    if (parts.length > 3) {
      final v = int.tryParse(parts[3]);
      if (v != null && AlarmLevel.isValid(v)) {
        level = v;
      } else if (parts[3] == '0') {
        level = 100;
      }
    }
    final vibrate = parts.length > 4 ? parts[4] != '0' : true;
    return (
      offsets: offs.isEmpty ? fallback : offs,
      enabled: parts[1] == '1',
      sound: sound,
      level: level,
      vibrate: vibrate
    );
  }

  static Future<void> save(
    String sessionId,
    String profileId,
    List<int> offsets,
    bool enabled, {
    String sound = defaultSound,
    int level = defaultLevel,
    bool vibrate = true,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key(sessionId, profileId),
        '${offsets.join(',')}|${enabled ? 1 : 0}|$sound|$level|${vibrate ? 1 : 0}');
  }

  // Label jujur presisi berdasar izin exact.
  static String precisionLabel({required bool exactGranted, required bool enabled}) {
    if (!enabled) return 'Mati';
    if (!exactGranted) return 'Tidak presisi';
    return 'Presisi';
  }
}
