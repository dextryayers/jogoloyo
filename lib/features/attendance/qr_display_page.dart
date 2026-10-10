// QR tampil guru F5.1: refresh 60 detik dengan countdown.
// PIN cadangan 6 digit refresh 10 menit. Kunci dari secure storage.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/local/les_store.dart';
import '../attendance/qr_service.dart';

class QrDisplayPage extends ConsumerStatefulWidget {
  final String sessionId;
  const QrDisplayPage({super.key, required this.sessionId});
  @override
  ConsumerState<QrDisplayPage> createState() => _State();
}

class _State extends ConsumerState<QrDisplayPage> {
  QrPayload? _qr;
  String _pin = '-';
  int _left = 60;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _refresh();
    _t = Timer.periodic(const Duration(seconds: 1), (_) async {
      setState(() => _left = _left <= 1 ? 60 : _left - 1);
      if (_left == 60) await _refresh();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final key = await ref.read(lesStoreProvider).ensureLesKey();
    final svc = QrService(key);
    setState(() {
      _qr = svc.build(widget.sessionId);
      _pin = svc.backupPin(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kode Absensi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_qr == null)
                    const CircularProgressIndicator()
                  else
                    QrImageView(data: _qr!.encode(), size: 220),
                  const SizedBox(height: 8),
                  Text('Berganti dalam $_left detik. Screenshot basi otomatis ditolak.',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text('PIN cadangan: $_pin'),
              subtitle: const Text('Berubah tiap 10 menit. Maks 5 salah per sesi.'),
              trailing: TextButton(onPressed: _refresh, child: const Text('Refresh')),
            ),
          ),
          const Text('Jangan bagikan di grup umum. Tampilkan hanya di kelas.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
