// F5.1 QR rotating HMAC 60 detik plus PIN cadangan 10 menit.
// Message: session_id:epoch_60. Sig HMAC kunci les. Toleransi 90 detik untuk jam miring.
import 'dart:convert';
import '../../core/security/hmac.dart';

class QrPayload {
  final String sessionId;
  final int epoch60;
  final String sig;
  QrPayload({required this.sessionId, required this.epoch60, required this.sig});

  String encode() => base64Url.encode(utf8.encode(jsonEncode({
        'v': 1,
        'session_id': sessionId,
        'epoch_60': epoch60,
        'sig': sig,
      })));

  static QrPayload? decode(String raw) {
    try {
      final m = jsonDecode(utf8.decode(base64Url.decode(raw))) as Map<String, dynamic>;
      return QrPayload(
        sessionId: m['session_id'] as String,
        epoch60: (m['epoch_60'] as num).toInt(),
        sig: m['sig'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

class QrService {
  final String lesKeyB64;
  QrService(this.lesKeyB64);

  QrPayload build(String sessionId, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    final e60 = now ~/ 60;
    final sig = LesHmac.sign(lesKeyB64, LesHmac.qrMessage(sessionId, e60));
    return QrPayload(sessionId: sessionId, epoch60: e60, sig: sig);
  }

  bool verify(QrPayload p, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    final cur = now ~/ 60;
    for (final e in [cur, cur - 1]) {
      if (e == p.epoch60 &&
          LesHmac.verify(lesKeyB64, LesHmac.qrMessage(p.sessionId, e), p.sig)) {
        return true;
      }
    }
    // Tolak jika basi lebih dari 90 detik.
    final age = now - p.epoch60 * 60;
    if (age > 90) return false;
    return LesHmac.verify(lesKeyB64, LesHmac.qrMessage(p.sessionId, p.epoch60), p.sig) && age <= 90;
  }

  String backupPin(String sessionId, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    return LesHmac.backupPin(lesKeyB64, sessionId, now ~/ 600);
  }

  bool verifyPin(String sessionId, String input, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    final cur = now ~/ 600;
    for (final e in [cur, cur - 1]) {
      if (LesHmac.backupPin(lesKeyB64, sessionId, e) == input.trim()) return true;
    }
    return false;
  }
}
