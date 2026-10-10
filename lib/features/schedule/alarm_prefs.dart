// Preferensi alarm per sesi per profil. Simpan di SharedPreferences.
// Kunci: alarm_{sessionId}_{profileId}. Value: offsets CSV plus enabled plus suara plus mode keras.
// Format: 30,10|1|suara1|1. Lama 30,10|1 tetap dibaca dengan default suara1 dan keras aktif.
// Default siswa: 30,10 aktif, Suara 1, Mode Keras aktif.
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

class AlarmPrefs {
  static const defaultSound = 'suara1';

  static String key(String sessionId, String profileId) => 'alarm_${sessionId}_$profileId';

  static Future<({List<int> offsets, bool enabled, String sound, bool loud})> load(
    String sessionId,
    String profileId, {
    List<int> fallback = const [30, 10],
  }) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key(sessionId, profileId));
    if (raw == null) return (offsets: fallback, enabled: true, sound: defaultSound, loud: true);
    final parts = raw.split('|');
    if (parts.length < 2) return (offsets: fallback, enabled: true, sound: defaultSound, loud: true);
    final offs = parts[0].split(',').where((e) => e.isNotEmpty).map(int.parse).toList();
    final sound = parts.length > 2 && AlarmSound.isValid(parts[2]) ? parts[2] : defaultSound;
    final loud = parts.length > 3 ? parts[3] == '1' : true;
    return (offsets: offs.isEmpty ? fallback : offs, enabled: parts[1] == '1', sound: sound, loud: loud);
  }

  static Future<void> save(
    String sessionId,
    String profileId,
    List<int> offsets,
    bool enabled, {
    String sound = defaultSound,
    bool loud = true,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        key(sessionId, profileId), '${offsets.join(',')}|${enabled ? 1 : 0}|$sound|${loud ? 1 : 0}');
  }

  // Label jujur presisi berdasar izin exact.
  static String precisionLabel({required bool exactGranted, required bool enabled}) {
    if (!enabled) return 'Mati';
    if (!exactGranted) return 'Tidak presisi';
    return 'Presisi';
  }
}
