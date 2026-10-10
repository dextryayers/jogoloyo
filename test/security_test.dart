// Uji PIN hash dan HMAC kunci les. Murni, tanpa HP.
import 'package:flutter_test/flutter_test.dart';
import 'package:jogoloyo_les/core/security/pin_hash.dart';
import 'package:jogoloyo_les/core/security/hmac.dart';
import 'dart:convert';

void main() {
  test('PIN valid 6 digit dan verifikasi benar', () {
    expect(PinHash.isPinValid('123456'), true);
    expect(PinHash.isPinValid('12345'), false);
    final salt = PinHash.makeSalt();
    final h = PinHash.hash('123456', salt);
    expect(PinHash.verify('123456', salt, h), true);
    expect(PinHash.verify('654321', salt, h), false);
  });

  test('HMAC QR stabil dan PIN cadangan 6 digit', () {
    final key = base64Url.encode(List<int>.generate(32, (i) => i));
    final msg = LesHmac.qrMessage('sess1', 12345);
    final sig = LesHmac.sign(key, msg);
    expect(LesHmac.verify(key, msg, sig), true);
    expect(LesHmac.verify(key, '${msg}x', sig), false);
    final pin = LesHmac.backupPin(key, 'sess1', 999);
    expect(pin.length, 6);
  });
}
