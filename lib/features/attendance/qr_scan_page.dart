// Pindai QR siswa F5.1: verifikasi HMAC, tolak basi, tulis hadir.
// PIN manual sebagai fallback jika kamera bermasalah.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/local/les_store.dart';
import 'attendance_repo.dart';
import 'qr_service.dart';

class QrScanPage extends ConsumerStatefulWidget {
  final String sessionId;
  const QrScanPage({super.key, required this.sessionId});
  @override
  ConsumerState<QrScanPage> createState() => _State();
}

class _State extends ConsumerState<QrScanPage> {
  bool _done = false;
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai untuk Hadir')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (cap) async {
                if (_done) return;
                final raw = cap.barcodes.firstOrNull?.rawValue;
                if (raw == null) return;
                final p = QrPayload.decode(raw);
                if (p == null || p.sessionId != widget.sessionId) {
                  _fail('Kode tidak cocok dengan sesi ini.');
                  return;
                }
                try {
                  final key = await ref.read(lesStoreProvider).ensureLesKey();
                  final ok = QrService(key).verify(p);
                  if (!ok) {
                    _fail('Kode kedaluwarsa. Minta kode baru ke guru.');
                    return;
                  }
                  _done = true;
                  await ref.read(attendanceRepoProvider).markPresent(
                        sessionId: widget.sessionId,
                        profileId: 'siswa-sinta',
                        method: 'qr',
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kehadiran tercatat. Sampai jumpa di kelas.')));
                } catch (e) {
                  _fail('$e');
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                        labelText: 'PIN 6 digit', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final key = await ref.read(lesStoreProvider).ensureLesKey();
                      final ok = QrService(key).verifyPin(widget.sessionId, _pin.text);
                      if (!ok) {
                        await ref
                            .read(attendanceRepoProvider)
                            .notePinFail(widget.sessionId, 'siswa-sinta');
                        _fail('PIN salah. Cek lagi.');
                        return;
                      }
                      await ref.read(attendanceRepoProvider).clearPinFail(widget.sessionId, 'siswa-sinta');
                      await ref.read(attendanceRepoProvider).markPresent(
                            sessionId: widget.sessionId,
                            profileId: 'siswa-sinta',
                            method: 'pin',
                          );
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kehadiran tercatat via PIN.')));
                    } catch (e) {
                      _fail('$e');
                    }
                  },
                  child: const Text('Kirim'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _fail(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
