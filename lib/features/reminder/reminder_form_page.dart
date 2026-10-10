// Form pengingat: judul, tanggal, jam, slot cepat, harian, suara, mode keras.
// Simpan langsung jadwalkan alarm exact offset 0. Ada tombol Tes dan Hapus.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../core/log/app_log.dart';
import '../../data/local/simple_store.dart';
import '../../shared/widgets/level_picker.dart';
import '../../features/schedule/alarm_prefs.dart';

class ReminderFormPage extends ConsumerStatefulWidget {
  final String? reminderId;
  const ReminderFormPage({super.key, this.reminderId});
  @override
  ConsumerState<ReminderFormPage> createState() => _State();
}

class _State extends ConsumerState<ReminderFormPage> {
  final _title = TextEditingController();
  // Tanggal default = hari ini WIB, bukan waktu lokal HP. Konsisten di semua zona.
  DateTime _day = DateTime.now().toUtc().add(const Duration(hours: 7));
  TimeOfDay _time = const TimeOfDay(hour: 6, minute: 0);
  bool _daily = false;
  String _sound = 'suara1';
  int _level = 200;
  bool _vibrate = true;
  bool _enabled = true;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(simpleStoreProvider);
    _sound = await store.defaultSound();
    _level = await store.defaultLevel();
    _vibrate = await store.defaultVibrate();
    if (widget.reminderId != null) {
      final all = await store.loadReminders();
      final r = all.where((e) => e.id == widget.reminderId).firstOrNull;
      if (r != null) {
        final w = r.whenUtc.toUtc().add(const Duration(hours: 7));
        _title.text = r.title;
        _day = DateTime(w.year, w.month, w.day);
        _time = TimeOfDay(hour: w.hour, minute: w.minute);
        _daily = r.daily;
        _sound = r.sound;
        _level = r.level;
        _vibrate = r.vibrate;
        _enabled = r.enabled;
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(appBar: AppBar(title: const Text('Pengingat')), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.reminderId == null ? 'Pengingat Baru' : 'Ubah Pengingat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Judul', hintText: 'Contoh: Minum obat'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final todayWib =
                        DateTime.now().toUtc().add(const Duration(hours: 7));
                    final today = DateTime(todayWib.year, todayWib.month, todayWib.day);
                    final d = await showDatePicker(
                      context: context,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 365)),
                      initialDate: _day.isBefore(today) ? today : _day,
                    );
                    if (d != null) setState(() => _day = d);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('${_day.day}/${_day.month}/${_day.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in appSlots)
                ActionChip(
                  label: Text(s),
                  onPressed: () async {
                    final hm = await ref.read(simpleStoreProvider).slotTime(s);
                    setState(() => _time = parseHm(hm));
                  },
                ),
            ],
          ),
          SwitchListTile(
            value: _daily,
            onChanged: (v) => setState(() => _daily = v),
            title: const Text('Berbunyi tiap hari'),
            subtitle: const Text('Jam yang sama setiap hari plus getar.'),
          ),
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
                    AlarmService().test('urgent', sound: s.id, level: _level, vibrate: _vibrate);
                  },
                ),
            ],
          ),
          LevelPicker(
            level: _level,
            vibrate: _vibrate,
            onLevel: (v) {
              setState(() => _level = v);
              AlarmService().test('urgent', sound: _sound, level: v, vibrate: _vibrate);
            },
            onVibrate: (v) => setState(() => _vibrate = v),
          ),
          SwitchListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: const Text('Aktif'),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AlarmService()
                      .test('urgent', sound: _sound, level: _level, vibrate: _vibrate),
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
              if (widget.reminderId != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(simpleStoreProvider).deleteReminder(widget.reminderId!);
                      await ref.read(simpleStoreProvider).rescheduleAll();
                      ref.invalidate(remindersProvider);
                      if (!context.mounted) return;
                      context.pop();
                    },
                    icon: const Icon(Icons.delete_outline, color: JogloColors.danger),
                    label: const Text('Hapus', style: TextStyle(color: JogloColors.danger)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final wib = DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute);
                var utc = wib.subtract(const Duration(hours: 7));
                final hm =
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
                if (!_daily && !utc.isAfter(DateTime.now().toUtc())) {
                  messenger.showSnackBar(SnackBar(
                      content: Text(
                          'Jam $hm WIB hari ini sudah lewat. Pilih jam berikutnya atau aktifkan harian.')));
                  return;
                }
                if (!_enabled) {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Status mati. Nyalakan Aktif agar berbunyi.')));
                  return;
                }
                final id = widget.reminderId ?? const Uuid().v4();
                await ref.read(simpleStoreProvider).upsertReminder(Reminder(
                      id: id,
                      title: _title.text.trim().isEmpty ? 'Pengingat' : _title.text.trim(),
                      whenUtc: utc,
                      sound: _sound,
                      level: _level,
                      vibrate: _vibrate,
                      enabled: _enabled,
                      daily: _daily,
                    ));
                final res = await ref.read(simpleStoreProvider).rescheduleAll();
                AppLog.record('reminder_save', '$id:${res.scheduled}');
                final perm = await AlarmService().permissions();
                final exact = perm['exactAlarm'] ?? true;
                final armed = await AlarmService().isArmed(
                    sessionId: id, profileId: 'me', offsets: const [0]);
                ref.invalidate(remindersProvider);
                if (!context.mounted) return;
                context.pop();
                messenger.showSnackBar(SnackBar(
                    content: Text(armed
                        ? 'Tersimpan jam $hm WIB. Alarm terpasang dan akan berbunyi.'
                        : res.scheduled > 0
                            ? 'Tersimpan jam $hm WIB tapi belum terpasang di sistem. Buka Setting lalu cek izin.'
                            : 'Tersimpan tapi alarm gagal dijadwalkan. Buka Setting lalu cek izin.')));
                if (!exact && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Izin presisi mati. Bunyi bisa telat. Nyalakan di Setting.')));
                }
              },
              child: const Text('Simpan Pengingat'),
            ),
          ),
        ],
      ),
    );
  }
}
