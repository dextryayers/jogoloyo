// PIN nyata F1 deep: verifikasi hash ke DB plus lockout waktu 5 menit.
// Gagal 5 kali dalam 10 menit maka kunci sampai waktu tampil. Tercatat di log.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/log/app_log.dart';
import '../../data/local/les_store.dart';

class PinPage extends ConsumerStatefulWidget {
  const PinPage({super.key});
  @override
  ConsumerState<PinPage> createState() => _State();
}

class _State extends ConsumerState<PinPage> {
  final _c = TextEditingController();
  String _info = 'Pilih profil: Sinta (Siswa). Masukkan PIN 6 digit.';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<bool> _locked(String pid) async {
    final p = await SharedPreferences.getInstance();
    final until = p.getInt('lock_$pid') ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  Future<String> _lockLabel(String pid) async {
    final p = await SharedPreferences.getInstance();
    final until = p.getInt('lock_$pid') ?? 0;
    final t = DateTime.fromMillisecondsSinceEpoch(until);
    return 'Terkunci sampai ${t.hour}:${t.minute.toString().padLeft(2, '0')}. Minta reset ke owner jika lupa.';
  }

  Future<void> _noteFail(String pid) async {
    final p = await SharedPreferences.getInstance();
    final k = 'fail_${pid}_count';
    final n = (p.getInt(k) ?? 0) + 1;
    await p.setInt(k, n);
    await p.setInt('fail_${pid}_at', DateTime.now().millisecondsSinceEpoch);
    if (n >= 5) {
      await p.setInt('lock_$pid', DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch);
      await p.setInt(k, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masukkan PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_info, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _c,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'PIN 6 digit'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  const pid = 'siswa-sinta';
                  final messenger = ScaffoldMessenger.of(context);
                  if (_c.text.length != 6) {
                    messenger.showSnackBar(const SnackBar(content: Text('PIN harus 6 digit.')));
                    return;
                  }
                  if (await _locked(pid)) {
                    messenger.showSnackBar(SnackBar(content: Text(await _lockLabel(pid))));
                    return;
                  }
                  try {
                    await ref.read(lesStoreProvider).verifyPin(pid, _c.text);
                    final p = await SharedPreferences.getInstance();
                    await p.setInt('fail_${pid}_count', 0);
                    AppLog.record('login', pid);
                    if (!context.mounted) return;
                    context.go('/home');
                  } catch (_) {
                    await _noteFail(pid);
                    AppLog.record('pin_fail', pid);
                    if (await _locked(pid)) {
                      if (!context.mounted) return;
                      messenger.showSnackBar(SnackBar(content: Text(await _lockLabel(pid))));
                    } else {
                      if (!context.mounted) return;
                      messenger.showSnackBar(const SnackBar(content: Text('PIN salah. Cek lagi.')));
                    }
                    setState(() => _info = 'Gagal masuk. Sisa 5 percobaan sebelum kunci 5 menit.');
                  }
                },
                child: const Text('Masuk'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Lupa PIN: minta reset ke owner dengan PIN owner. Semua gagal tercatat.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
