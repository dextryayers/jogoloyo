// Setup notifikasi: pilih suara, mode keras, set jam tiap slot, tes bunyi.
// Tombol simpan membuat pengingat harian per slot aktif. Bunyi dijamin via alarm exact.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../core/log/app_log.dart';
import '../../data/local/simple_store.dart';
import '../../features/schedule/alarm_prefs.dart';

class NotifSetupPage extends ConsumerStatefulWidget {
  const NotifSetupPage({super.key});
  @override
  ConsumerState<NotifSetupPage> createState() => _State();
}

class _State extends ConsumerState<NotifSetupPage> {
  String _sound = 'suara1';
  bool _loud = true;
  Map<String, String> _times = defaultSlotTimes();
  final Map<String, bool> _on = {'Pagi': true, 'Siang': false, 'Sore': true, 'Malam': false};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final store = ref.read(simpleStoreProvider);
    final t = <String, String>{};
    for (final s in appSlots) {
      t[s] = await store.slotTime(s);
    }
    setState(() {
      _sound = p.getString('default_sound') ?? 'suara1';
      _loud = p.getBool('default_loud') ?? true;
      _times = t;
    });
  }

  Future<void> _pickTime(String slot) async {
    final cur = parseHm(_times[slot] ?? '06:00');
    final t = await showTimePicker(context: context, initialTime: cur);
    if (t == null) return;
    final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    await ref.read(simpleStoreProvider).setSlotTime(slot, hm);
    setState(() => _times[slot] = hm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atur Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Kapan berbunyi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Text('Aktifkan slot lalu set jamnya. Tes dulu sebelum simpan.',
              style: TextStyle(color: JogloColors.muted)),
          const SizedBox(height: 12),
          for (final s in appSlots)
            Card(
              child: SwitchListTile(
                value: _on[s] ?? false,
                onChanged: (v) => setState(() => _on[s] = v),
                title: Text('$s . ${_times[s]}'),
                subtitle: const Text('Berbunyi tiap hari plus getar.'),
                secondary: TextButton(
                  onPressed: () => _pickTime(s),
                  child: const Text('Set Jam'),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text('Suara', style: TextStyle(fontWeight: FontWeight.w800)),
          Wrap(
            spacing: 8,
            children: [
              for (final s in AlarmSound.options)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _sound == s.id,
                  onSelected: (_) {
                    setState(() => _sound = s.id);
                    AlarmService().test('urgent', sound: s.id, loud: _loud);
                  },
                ),
            ],
          ),
          SwitchListTile(
            value: _loud,
            onChanged: (v) => setState(() => _loud = v),
            title: const Text('Mode Keras 200 persen'),
            subtitle: const Text('Volume dipaksa maksimal plus getar kuat.'),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AlarmService().test('urgent', sound: _sound, loud: _loud),
                  icon: const Icon(Icons.alarm),
                  label: const Text('Tes Bunyi'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AlarmService().openSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Izin'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('default_sound', _sound);
                        await prefs.setBool('default_loud', _loud);
                        final store = ref.read(simpleStoreProvider);
                        for (final s in appSlots) {
                          if (!(_on[s] ?? false)) continue;
                          await store.upsertReminder(Reminder(
                            id: 'slot_${s.toLowerCase()}',
                            title: 'Waktunya $s',
                            whenUtc: store.todayWibToUtc(_times[s] ?? '06:00'),
                            sound: _sound,
                            loud: _loud,
                            daily: true,
                          ));
                        }
                        await store.rescheduleAll();
                        await prefs.setBool('notif_done', true);
                        AppLog.record('notif_setup', _sound);
                        if (!context.mounted) return;
                        context.go('/home');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Notifikasi aktif. Akan berbunyi plus getar tepat waktu.')));
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Menyimpan...' : 'Simpan dan Masuk'),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Izin exact membuat bunyi tepat menit. Jika ditolak, label Tidak presisi muncul.',
              style: TextStyle(fontSize: 12, color: JogloColors.muted)),
        ],
      ),
    );
  }
}
