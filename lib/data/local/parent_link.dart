// Kode tautan ortu lokal: 6 digit, TTL 24 jam, sekali pakai.
// Batas: 1 anak maks 2 ortu, 1 ortu maks 4 anak. Klaim menghapus kode agar tidak dipakai ulang.
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class ParentLinkService {
  static const kPrefix = 'parent_link_';
  static const kChildPrefix = 'links_child_';
  static const kParentPrefix = 'links_parent_';
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

  Future<List<String>> linksForChild(String childId) async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList('$kChildPrefix$childId') ?? [];
  }

  Future<List<String>> linksForParent(String parentId) async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList('$kParentPrefix$parentId') ?? [];
  }

  Future<String?> claim({required String code, required String parentId}) async {
    final p = await SharedPreferences.getInstance();
    final key = '$kPrefix${code.trim().toUpperCase()}';
    final raw = p.getString(key);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length != 2) {
      await p.remove(key);
      return null;
    }
    final exp = DateTime.tryParse(parts[1]);
    final childId = parts[0];
    if (exp == null || DateTime.now().toUtc().isAfter(exp)) {
      await p.remove(key);
      return null;
    }
    final childLinks = await linksForChild(childId);
    if (childLinks.length >= 2 && !childLinks.contains(parentId)) return null;
    final parentLinks = await linksForParent(parentId);
    if (parentLinks.length >= 4 && !parentLinks.contains(childId)) return null;
    await p.remove(key);
    if (!childLinks.contains(parentId)) {
      await p.setStringList('$kChildPrefix$childId', [...childLinks, parentId]);
    }
    if (!parentLinks.contains(childId)) {
      await p.setStringList('$kParentPrefix$parentId', [...parentLinks, childId]);
    }
    return childId;
  }
}
