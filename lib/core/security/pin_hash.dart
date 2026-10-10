// PIN lokal: hash dengan salt per akun memakai SHA-256 berulang.
// Bukan bcrypt agar tanpa native tambahan. Cukup untuk V.01.0 lokal.
// PIN tidak pernah disimpan plaintext dan tidak pernah ditulis ke log.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class PinHash {
  static String makeSalt([int len = 16]) {
    final r = Random.secure();
    final b = List<int>.generate(len, (_) => r.nextInt(256));
    return base64Url.encode(b);
  }

  static String hash(String pin, String salt) {
    var data = Uint8List.fromList(utf8.encode('$salt::$pin'));
    for (var i = 0; i < 5000; i++) {
      data = Uint8List.fromList(sha256.convert(data).bytes);
    }
    return base64Url.encode(data);
  }

  static bool verify(String pin, String salt, String expect) {
    return hash(pin, salt) == expect;
  }

  static bool isPinValid(String pin) => RegExp(r'^\d{6}$').hasMatch(pin);
}
