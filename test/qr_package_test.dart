// Uji QR HMAC 60 detik dan PIN 10 menit. Murni tanpa HP.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:jogoloyo_les/features/attendance/qr_service.dart';
import 'package:jogoloyo_les/features/teacher/teacher_package.dart';

void main() {
  final key = base64Url.encode(List<int>.generate(32, (i) => i + 1));

  test('QR valid saat ini, basi ditolak', () {
    final svc = QrService(key);
    final now = DateTime.utc(2026, 10, 18, 8, 30);
    final p = svc.build('sess1', nowUtc: now);
    expect(svc.verify(p, nowUtc: now), true);
    final late = now.add(const Duration(minutes: 5));
    expect(svc.verify(p, nowUtc: late), false);
  });

  test('PIN berubah tiap 10 menit dan toleransi 1 slot', () {
    final svc = QrService(key);
    final t0 = DateTime.utc(2026, 10, 18, 8, 0);
    final t9 = t0.add(const Duration(minutes: 9));
    final t11 = t0.add(const Duration(minutes: 11));
    final pin0 = svc.backupPin('sess1', nowUtc: t0);
    expect(svc.verifyPin('sess1', pin0, nowUtc: t9), true);
    expect(svc.verifyPin('sess1', pin0, nowUtc: t11.add(const Duration(minutes: 10))), false);
  });

  test('paket manifest valid, 1 byte ubah ditolak', () {
    final data = {'teacher': 'rina', 'status': 'PENDING'};
    final m = TeacherPackage.manifest(kind: 'pengajuan_guru', fromDevice: 'A1B2', data: data, lesKeyB64: key);
    expect(TeacherPackage.verifyManifest(m, data, key), true);
    final bad = Map<String, dynamic>.from(data)..['status'] = 'ACTIVE';
    expect(TeacherPackage.verifyManifest(m, bad, key), false);
  });
}
