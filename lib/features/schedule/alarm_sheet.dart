// Sheet alarm: toggle H-60 H-30 H-10, pilih Suara 1 sampai 6, Mode Keras 200 persen.
// H-10 ke bawah otomatis bunyi suara pilihan plus getar kuat walau app ditutup.
// Simpan ke AlarmPrefs lalu jadwalkan via Kotlin.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../data/local/app_db.dart';
import 'alarm_prefs.dart';

class AlarmSheet extends ConsumerStatefulWidget {
  final Session session;
  const AlarmSheet({super.key, required this.session});
  @override
  ConsumerState<AlarmSheet> createState() => _State();
}

class _State extends ConsumerState<AlarmSheet> {
  List<int> _offs = [30, 10];
  bool _on = true;
  bool _exact = true;
  bool _loading = true;
  String _sound = AlarmPrefs.defaultSound;
  bool _loud = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final p = await AlarmPrefs.load(widget.session.id, 'siswa-sinta');
    final perm = await AlarmService().permissions();
    if (!mounted) return;
    setState(() {
      _offs = p.offsets;
      _on = p.enabled;
      _sound = p.sound;
      _loud = p.loud;
      _exact = perm['exactAlarm'] ?? true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = AlarmPrefs.precisionLabel(exactGranted: _exact, enabled: _on);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                      child: Text('Atur Alarm',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !_on
                          ? const Color(0xFFEEEEEE)
                          : _exact
                              ? JogloColors.scheduledBg
                              : JogloColors.izinBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: !_on
                                ? JogloColors.muted
                                : _exact
                                    ? JogloColors.primaryDark
                                    : JogloColors.warning)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${widget.session.subject} . ${widget.session.room}',
                  style: const TextStyle(color: JogloColors.muted)),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                SwitchListTile(
                  value: _on,
                  onChanged: (v) => setState(() => _on = v),
                  title: const Text('Aktifkan alarm sesi ini'),
                  subtitle: const Text('H-10 otomatis bunyi plus getar.'),
                ),
                for (final o in [60, 30, 10])
                  CheckboxListTile(
                    value: _offs.contains(o),
                    onChanged: !_on
                        ? null
                        : (v) => setState(() {
                              if (v == true) {
                                _offs = [..._offs, o]..sort();
                              } else {
                                _offs = _offs.where((e) => e != o).toList();
                              }
                            }),
                    title: Text('H-$o menit'),
                    subtitle: Text(o == 60
                        ? 'Info biasa.'
                        : o == 30
                            ? 'Pengingat suara.'
                            : 'Bunyi otomatis plus getar kuat.'),
                  ),
                const Divider(),
                const Text('Suara Alarm', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in AlarmSound.options)
                      ChoiceChip(
                        label: Text(s.label),
                        selected: _sound == s.id,
                        onSelected: !_on
                            ? null
                            : (_) {
                                setState(() => _sound = s.id);
                                AlarmService().test('urgent', sound: s.id, loud: _loud);
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Ketuk untuk dengar langsung.',
                    style: TextStyle(fontSize: 12, color: JogloColors.muted)),
                SwitchListTile(
                  value: _loud,
                  onChanged: !_on ? null : (v) => setState(() => _loud = v),
                  title: const Text('Mode Keras 200 persen'),
                  subtitle: const Text('Volume alarm dipaksa maksimal plus getar kuat. Default aktif.'),
                ),
                if (!_exact)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: JogloColors.izinBg, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Expanded(
                            child: Text(
                                'Izin alarm presisi mati. Alarm jadi tidak presisi. Buka Pengaturan untuk menyalakan.')),
                        TextButton(
                          onPressed: () => AlarmService().openSettings(),
                          child: const Text('Buka'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => AlarmService().test('info', sound: _sound, loud: _loud),
                        icon: const Icon(Icons.volume_up_outlined),
                        label: const Text('Tes Info'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => AlarmService().test('urgent', sound: _sound, loud: _loud),
                        icon: const Icon(Icons.alarm),
                        label: const Text('Tes Keras'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _offs.isEmpty && _on
                        ? null
                        : () async {
                            await AlarmPrefs.save(widget.session.id, 'siswa-sinta',
                                _offs, _on, sound: _sound, loud: _loud);
                            final ok = _on
                                ? await AlarmService().schedule(
                                    sessionId: widget.session.id,
                                    profileId: 'siswa-sinta',
                                    startUtc: widget.session.startUtc,
                                    offsets: _offs,
                                    title: widget.session.subject,
                                    room: widget.session.room,
                                    sound: _sound,
                                    loud: _loud,
                                  )
                                : await AlarmService()
                                    .cancel(widget.session.id, 'siswa-sinta');
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(ok
                                    ? 'Alarm tersimpan: ${_offs.map((e) => 'H-$e').join(', ')}, ${_soundLabel()}, Mode Keras ${_loud ? 'aktif' : 'mati'}.'
                                    : 'Gagal menjadwalkan. Alarm ditandai Menunggu sinkron.')));
                          },
                    child: const Text('Simpan Alarm'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Panduan baterai: Xiaomi aktifkan Autostart. Samsung set Battery Unrestricted. Oppo dan Vivo izinkan background.',
                  style: TextStyle(fontSize: 12, color: JogloColors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _soundLabel() {
    for (final s in AlarmSound.options) {
      if (s.id == _sound) return s.label;
    }
    return 'Suara 1';
  }
}
