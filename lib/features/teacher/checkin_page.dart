// Check in guru F4.4: checkbox kepatuhan wajib, tanpa centang tombol mati.
// Menyimpan ke tabel checkins dengan timestamp. Tanpa GPS presisi di V.01.0.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/copy_rules.dart';
import 'teacher_repo.dart';

class CheckinPage extends ConsumerStatefulWidget {
  final String sessionId;
  final String teacherId;
  const CheckinPage({super.key, required this.sessionId, required this.teacherId});
  @override
  ConsumerState<CheckinPage> createState() => _State();
}

class _State extends ConsumerState<CheckinPage> {
  bool _ok = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In Mengajar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_user_outlined),
              title: Text('Foto profil resmi kamu ditampilkan sebagai pengingat.'),
              subtitle: Text('Pastikan busana rapi sebelum menekan tombol.'),
            ),
          ),
          CheckboxListTile(
            value: _ok,
            onChanged: (v) => setState(() => _ok = v ?? false),
            title: const Text(CopyRules.compliance),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: !_ok || _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await ref.read(teacherRepoProvider).checkin(
                            sessionId: widget.sessionId,
                            teacherId: widget.teacherId,
                            compliance: _ok,
                          );
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Check in tercatat. Selamat mengajar.')));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            icon: const Icon(Icons.login),
            label: Text(_saving ? 'Menyimpan...' : 'Check In'),
          ),
          const SizedBox(height: 8),
          const Text('Tanpa centang, check in ditolak sistem. Pelanggaran bisa disuspend admin.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
