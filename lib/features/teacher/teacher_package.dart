// F4.3 Paket pengajuan beda HP. ZIP berisi manifest, data, dan foto.
// Diamankan HMAC kunci les. Paket palsu 1 byte pun ditolak.
// Jenis: pengajuan_guru, hasil_review.
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class TeacherPackage {
  static Map<String, dynamic> manifest({
    required String kind,
    required String fromDevice,
    required Map<String, dynamic> data,
    required String lesKeyB64,
  }) {
    final dataJson = jsonEncode(data);
    final sha = sha256.convert(utf8.encode(dataJson)).toString();
    final sig = _hmac(lesKeyB64, '$kind:$sha');
    return {
      'v': 1,
      'kind': kind,
      'from_device': fromDevice,
      'created_utc': DateTime.now().toUtc().toIso8601String(),
      'sha256_data': sha,
      'sig': sig,
    };
  }

  static String _hmac(String keyB64, String msg) {
    final key = base64Url.decode(keyB64);
    return Hmac(sha256, key).convert(utf8.encode(msg)).toString();
  }

  static bool verifyManifest(Map<String, dynamic> manifest, Map<String, dynamic> data, String lesKeyB64) {
    final kind = manifest['kind'] as String? ?? '';
    final sha = manifest['sha256_data'] as String? ?? '';
    final sig = manifest['sig'] as String? ?? '';
    final calcSha = sha256.convert(utf8.encode(jsonEncode(data))).toString();
    if (calcSha != sha) return false;
    return _hmac(lesKeyB64, '$kind:$sha') == sig;
  }

  static Future<File> buildZip({
    required String kind,
    required Map<String, dynamic> data,
    required List<File> files,
    required String lesKeyB64,
    required String deviceId,
  }) async {
    final m = manifest(kind: kind, fromDevice: deviceId, data: data, lesKeyB64: lesKeyB64);
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/jogoloyo_${kind}_${DateTime.now().toUtc().millisecondsSinceEpoch}.zip');
    final enc = ZipFileEncoder()..create(out.path);
    enc.addArchiveFile(ArchiveFile('manifest.json', jsonEncode(m).length, utf8.encode(jsonEncode(m))));
    enc.addArchiveFile(ArchiveFile('data.json', jsonEncode(data).length, utf8.encode(jsonEncode(data))));
    for (final f in files) {
      if (await f.exists()) enc.addFile(f, 'files/${f.uri.pathSegments.last}');
    }
    enc.close();
    return out;
  }

  static String packageError(String code) {
    switch (code) {
      case 'bad_sig':
        return 'Paket tidak valid. Minta file asli dari pengirim.';
      case 'bad_sha':
        return 'File tidak lengkap. Minta kirim ulang file asli.';
      default:
        return 'Paket tidak bisa dibaca. Minta kirim ulang.';
    }
  }

  static String newDeviceId() => const Uuid().v4().substring(0, 4).toUpperCase();
}
