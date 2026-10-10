// Tab Saya: akun, tagihan, alarm, sync paket, backup. Semua lokal.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/alarm/alarm_service.dart';
import '../../data/local/parent_link.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _linkCode;
  final _claim = TextEditingController();

  @override
  void dispose() {
    _claim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Akun Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Sinta . Siswa'),
              subtitle: Text('Kelas 8 . PIN aktif'),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.family_restroom_outlined),
                  title: const Text('Tautan Ortu dan Anak'),
                  subtitle: Text(_linkCode == null
                      ? 'Buat kode 6 digit, berlaku 24 jam. Maks 2 ortu per anak.'
                      : 'Kode anak: $_linkCode . Berlaku 24 jam.'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final code =
                          await ParentLinkService().createForChild('sinta-id');
                      setState(() => _linkCode = code);
                    },
                    child: const Text('Buat Kode'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _claim,
                          decoration: const InputDecoration(
                            labelText: 'Klaim kode anak',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final child =
                              await ParentLinkService().claim(_claim.text);
                          final msg = child == null
                              ? 'Kode tidak valid atau kedaluwarsa.'
                              : 'Tertaut ke anak: $child. Hanya bisa baca.';
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text(msg)));
                        },
                        child: const Text('Klaim'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text('Tes Alarm'),
                  subtitle: const Text(
                      'Pastikan bunyi keluar sebelum hari H. Tes info dan urgent.'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => AlarmService().test('info'),
                        child: const Text('Info'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => AlarmService().test('urgent'),
                        child: const Text('Urgent'),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.battery_saver_outlined),
                  title: const Text('Izin dan Baterai'),
                  subtitle: const Text(
                      'Xiaomi Autostart. Samsung Unrestricted. Oppo Vivo background allow.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => AlarmService().openSettings(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Tagihan Les'),
                  subtitle: const Text('SPP Okt 2026 . Buat, bukti, verifikasi, kwitansi.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/bills'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync dan Backup'),
                  subtitle: const Text('Distribusi JSON, backup ZIP, riwayat jelas.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/sync'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
