// Service alarm Dart ke Kotlin via MethodChannel jogoloyo/alarm/v1.
// Semua waktu kirim sebagai ISO UTC. Selalu try catch dengan fallback lokal.
import 'package:flutter/services.dart';

class AlarmService {
  static const _ch = MethodChannel('jogoloyo/alarm/v1');

  Future<bool> schedule({
    required String sessionId,
    required String profileId,
    required DateTime startUtc,
    required List<int> offsets,
    required String title,
    required String room,
    String sound = 'suara1',
    int level = 200,
    bool vibrate = true,
  }) async {
    try {
      await _ch.invokeMethod('scheduleSessionAlarm', {
        'sessionId': '${sessionId}_$profileId',
        'startUtcIso': startUtc.toUtc().toIso8601String(),
        'offsetsMinutes': offsets,
        'title': title,
        'room': room,
        'sound': sound,
        'level': level,
        'vibrate': vibrate,
      });
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> cancel(String sessionId, String profileId) async {
    try {
      await _ch.invokeMethod('cancelSessionAlarm', {
        'sessionId': '${sessionId}_$profileId',
      });
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> test(String kind, {String sound = 'suara1', int level = 200, bool vibrate = true}) async {
    try {
      await _ch.invokeMethod(
          'testAlarm', {'kind': kind, 'sound': sound, 'level': level, 'vibrate': vibrate});
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stopSound() async {
    try {
      await _ch.invokeMethod('stopAlarmSound');
    } on PlatformException {
      return;
    }
  }

  // Cek nyata ke sistem apakah alarm sudah terpasang. Bukan tebakan.
  Future<bool> isArmed({
    required String sessionId,
    required String profileId,
    required List<int> offsets,
  }) async {
    try {
      final ok = await _ch.invokeMethod<bool>('isArmed', {
        'sessionId': '${sessionId}_$profileId',
        'offsetsMinutes': offsets,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestNotifications() async {
    try {
      await _ch.invokeMethod('requestNotifications');
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<Map<String, bool>> permissions() async {
    try {
      final m = await _ch.invokeMapMethod<String, bool>('arePermissionsGranted');
      return Map<String, bool>.from(m ?? {});
    } on PlatformException {
      return {};
    }
  }

  Future<void> openSettings() async {
    try {
      await _ch.invokeMethod('openExactAlarmSettings');
    } on PlatformException {
      return;
    }
  }
}
