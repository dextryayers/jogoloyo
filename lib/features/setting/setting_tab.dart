// Tab Setting: sistem notifikasi, suara default, mode keras, tes, lapor masalah, reset.
// Tanpa kode PIN. Semua simpel dan langsung jalan.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../features/schedule/alarm_prefs.dart';

class SettingTab extends ConsumerStatefulWidget {
  const SettingTab({super.key});
  @override
  ConsumerState<SettingTab> createState() => _State();
}

class _State extends ConsumerState<SettingTab> {
  String _sound = 'suara1';
  bool _loud = true;
  bool _exact = true;
  bool _notif = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final perm = await AlarmService().permissions();
    if (!mounted) return;
    setState(() {
      _sound = p.getString('default_sound') ?? 'suara1';
      _loud = p.getBool('default_loud') ?? true;
      _exact = perm['exactAlarm'] ?? true;
      _notif = perm['notifications'] ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Setting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Izin asli sistem. Minta, cek status, tes bunyi dan stop.',
              style: TextStyle(color: JogloColors.muted)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(_notif ? Icons.check_circle : Icons.warning,
                      color: _notif ? JogloColors.success : JogloColors.warning),
                  title: Text(_notif ? 'Notifikasi aktif' : 'Notifikasi mati'),
                  subtitle: const Text('Izin sistem agar banner muncul. Ketuk Minta.'),
                  trailing: TextButton(
                    onPressed: () async {
                      await AlarmService().requestNotifications();
                      await Future.delayed(const Duration(seconds: 1));
                      _load();
                    },
                    child: const Text('Minta'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(_exact ? Icons.check_circle : Icons.warning,
                      color: _exact ? JogloColors.success : JogloColors.warning),
                  title: Text(_exact ? 'Alarm presisi aktif' : 'Alarm presisi mati'),
                  subtitle: const Text('Harus aktif agar bunyi tepat menit plus getar.'),
                  trailing: TextButton(
                    onPressed: () async {
                      await AlarmService().openSettings();
                      _load();
                    },
                    child: const Text('Buka'),
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Suara default', style: TextStyle(fontWeight: FontWeight.w800)),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final s in AlarmSound.options)
                        ChoiceChip(
                          label: Text(s.label),
                          selected: _sound == s.id,
                          onSelected: (_) async {
                            final p = await SharedPreferences.getInstance();
                            await p.setString('default_sound', s.id);
                            setState(() => _sound = s.id);
                            AlarmService().test('urgent', sound: s.id, loud: _loud);
                          },
                        ),
                    ],
                  ),
                  SwitchListTile(
                    value: _loud,
                    onChanged: (v) async {
                      final p = await SharedPreferences.getInstance();
                      await p.setBool('default_loud', v);
                      setState(() => _loud = v);
                    },
                    title: const Text('Mode Keras 200 persen'),
                    subtitle: const Text('Volume dipaksa maksimal plus getar kuat.'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => AlarmService()
                              .test('urgent', sound: _sound, loud: _loud),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => AlarmService().stopSound(),
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                  const Text('Play bunyikan suara default. Stop hentikan seketika.',
                      style: TextStyle(fontSize: 12, color: JogloColors.muted)),
                ],
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: JogloColors.primary),
                  title: const Text('Ubah Waktu Notifikasi'),
                  subtitle: const Text('Jam tiap slot Pagi sampai Malam.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notif-setup'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.report_outlined, color: JogloColors.primary),
                  title: const Text('Lapor Masalah'),
                  subtitle: const Text('Kirim laporan plus log ke admin.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/report'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: JogloColors.danger),
                  title: const Text('Reset Semua', style: TextStyle(color: JogloColors.danger)),
                  subtitle: const Text('Hapus semua data. Mulai dari awal.'),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: const Text('Reset semua'),
                        content: const Text('Semua data di HP ini dihapus. Lanjut?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
                          ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Reset')),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    final p = await SharedPreferences.getInstance();
                    await p.clear();
                    if (!context.mounted) return;
                    context.go('/onboarding');
                  },
                ),
              ],
            ),
          ),
          const Center(
            child: Text('Les Jogoloyo V.02 simpel . 100 persen offline',
                style: TextStyle(fontSize: 12, color: JogloColors.muted)),
          ),
        ],
      ),
    );
  }
}
