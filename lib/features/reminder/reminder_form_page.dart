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
import '../../features/schedule/alarm_prefs.dart';

class ReminderFormPage extends ConsumerStatefulWidget {
  final String? reminderId;
  const ReminderFormPage({super.key, this.reminderId});
  @override
  ConsumerState<ReminderFormPage> createState() => _State();
}

class _State extends ConsumerState<ReminderFormPage> {
  final _title = TextEditingController();
  DateTime _day = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 6, minute: 0);
  bool _daily = false;
  String _sound = 'suara1';
  bool _loud = true;
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
    _loud = await store.defaultLoud();
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
        _loud = r.loud;
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
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: _day,
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
          SwitchListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: const Text('Aktif'),
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
                final wib = DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute);
                var utc = wib.subtract(const Duration(hours: 7));
                if (!_daily && !utc.isAfter(DateTime.now().toUtc())) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Waktu sudah lewat. Pilih jam berikutnya.')));
                  return;
                }
                final id = widget.reminderId ?? const Uuid().v4();
                await ref.read(simpleStoreProvider).upsertReminder(Reminder(
                      id: id,
                      title: _title.text.trim().isEmpty ? 'Pengingat' : _title.text.trim(),
                      whenUtc: utc,
                      sound: _sound,
                      loud: _loud,
                      enabled: _enabled,
                      daily: _daily,
                    ));
                final res = await ref.read(simpleStoreProvider).rescheduleAll();
                AppLog.record('reminder_save', '$id:${res.scheduled}');
                ref.invalidate(remindersProvider);
                if (!context.mounted) return;
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Tersimpan. Akan berbunyi plus getar tepat waktu.')));
              },
              child: const Text('Simpan Pengingat'),
            ),
          ),
        ],
      ),
    );
  }
}
