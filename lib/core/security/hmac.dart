// HMAC kunci les untuk QR absensi dan paket file.
// Kunci 32 byte dibuat saat setup owner dan simpan di secure storage.
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LesHmac {
  static String sign(String keyB64, String message) {
    final key = base64Url.decode(keyB64);
    final h = Hmac(sha256, key);
    return h.convert(utf8.encode(message)).toString();
  }

  static bool verify(String keyB64, String message, String sig) {
    return sign(keyB64, message) == sig;
  }

  // Payload QR: session_id + epoch_60. Contoh message: sess123:1730000000
  static String qrMessage(String sessionId, int epoch60) => '$sessionId:$epoch60';

  // PIN cadangan 6 digit dari epoch_600. Deterministik dan berubah tiap 10 menit.
  static String backupPin(String keyB64, String sessionId, int epoch600) {
    final sig = sign(keyB64, '$sessionId:$epoch600:pin');
    final n = int.parse(sig.substring(0, 8), radix: 16) % 1000000;
    return n.toString().padLeft(6, '0');
  }
}
