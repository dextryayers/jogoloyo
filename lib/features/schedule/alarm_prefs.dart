// Preferensi alarm per sesi per profil. Simpan di SharedPreferences.
// Kunci: alarm_{sessionId}_{profileId}. Value: offsets CSV plus enabled.
// Default siswa: 30,10 aktif. Default guru: 60,30 aktif.
import 'package:shared_preferences/shared_preferences.dart';

class AlarmPrefs {
  static String key(String sessionId, String profileId) => 'alarm_${sessionId}_$profileId';

  static Future<({List<int> offsets, bool enabled})> load(
    String sessionId,
    String profileId, {
    List<int> fallback = const [30, 10],
  }) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key(sessionId, profileId));
    if (raw == null) return (offsets: fallback, enabled: true);
    final parts = raw.split('|');
    if (parts.length != 2) return (offsets: fallback, enabled: true);
    final offs = parts[0].split(',').where((e) => e.isNotEmpty).map(int.parse).toList();
    return (offsets: offs.isEmpty ? fallback : offs, enabled: parts[1] == '1');
  }

  static Future<void> save(
    String sessionId,
    String profileId,
    List<int> offsets,
    bool enabled,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key(sessionId, profileId), '${offsets.join(',')}|${enabled ? 1 : 0}');
  }

  // Label jujur presisi berdasar izin exact.
  static String precisionLabel({required bool exactGranted, required bool enabled}) {
    if (!enabled) return 'Mati';
    if (!exactGranted) return 'Tidak presisi';
    return 'Presisi';
  }
}
