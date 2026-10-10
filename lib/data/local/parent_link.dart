// Kode tautan ortu lokal: 6 digit alfanumerik, TTL 24 jam.
// Tanpa server. Kode dibuat di HP anak, diklaim di HP yang sama atau via QR.
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class ParentLinkService {
  static const kPrefix = 'parent_link_';
  final _r = Random.secure();
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String makeCode() => List.generate(6, (_) => _chars[_r.nextInt(_chars.length)]).join();

  Future<String> createForChild(String childId) async {
    final p = await SharedPreferences.getInstance();
    final code = makeCode();
    final exp = DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String();
    await p.setString('$kPrefix$code', '$childId|$exp');
    return code;
  }

  Future<String?> claim(String code) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('$kPrefix${code.trim().toUpperCase()}');
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    final exp = DateTime.tryParse(parts[1]);
    if (exp == null || DateTime.now().toUtc().isAfter(exp)) {
      await p.remove('$kPrefix${code.trim().toUpperCase()}');
      return null;
    }
    return parts[0];
  }
}
