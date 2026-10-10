// Form tambah dan ubah jadwal F2.2. Validasi tajam sebelum simpan.
// Durasi 60, 90, 120. Di luar itu wajib catatan. Bentrok ditolak dengan pesan spesifik.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/alarm/alarm_service.dart';
import '../../core/alarm/resync.dart';
import '../../core/log/app_log.dart';
import '../../data/local/les_store.dart';
import '../../data/local/session_local_repo.dart';
import '../../data/local/session_repo.dart';
import 'schedule_providers.dart';

class SessionFormPage extends ConsumerStatefulWidget {
  final String? sessionId;
  const SessionFormPage({super.key, this.sessionId});
  @override
  ConsumerState<SessionFormPage> createState() => _State();
}

class _State extends ConsumerState<SessionFormPage> {
  final _subject = TextEditingController(text: 'Matematika kelas 8');
  String _teacher = 'guru-rina';
  String _room = 'Ruang A';
  DateTime _day = DateTime.utc(2026, 10, 18);
  TimeOfDay _start = const TimeOfDay(hour: 15, minute: 30);
  int _dur = 90;
  final _note = TextEditingController();
  bool _saving = false;
  String? _conflict;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final s = await SessionLocalRepo(ref.read(appDbProvider)).byId(widget.sessionId!);
    if (s == null || !mounted) return;
    final wib = s.startUtc.toUtc().add(const Duration(hours: 7));
    setState(() {
      _subject.text = s.subject;
      _teacher = s.teacherId;
      _room = s.room;
      _day = DateTime.utc(wib.year, wib.month, wib.day);
      _start = TimeOfDay(hour: wib.hour, minute: wib.minute);
      _dur = s.endUtc.difference(s.startUtc).inMinutes;
      if (![60, 90, 120].contains(_dur)) _dur = 90;
      _note.text = s.note.startsWith('Batal: ') ? '' : s.note;
    });
  }

  Future<void> _checkConflict() async {
    final startWib = DateTime(_day.year, _day.month, _day.day, _start.hour, _start.minute);
    final startUtc = startWib.subtract(const Duration(hours: 7));
    final endUtc = startUtc.add(Duration(minutes: _dur));
    try {
      final repo = SessionLocalRepo(ref.read(appDbProvider));
      final all = await repo.listRange(startUtc.subtract(const Duration(days: 1)), endUtc.add(const Duration(days: 1)));
      final cand = SessionInput(
        id: widget.sessionId ?? 'new',
        subject: _subject.text,
        teacherId: _teacher,
        startUtc: startUtc,
        endUtc: endUtc,
        room: _room,
      );
      SessionValidator.checkNoOverlap(
        cand,
        all.where((e) => e.id != (widget.sessionId ?? 'new')).map((e) => SessionInput(id: e.id, subject: e.subject, teacherId: e.teacherId, startUtc: e.startUtc, endUtc: e.endUtc, room: e.room)).toList(),
      );
      setState(() => _conflict = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aman. Tidak bentrok guru dan ruang.')));
    } catch (e) {
      setState(() => _conflict = '$e');
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sessionId == null ? 'Tambah Jadwal' : 'Ubah Jadwal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _subject,
            decoration: const InputDecoration(
                labelText: 'Mapel dan kelas', hintText: 'Contoh: Matematika kelas 8', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _teacher,
            decoration: const InputDecoration(labelText: 'Guru', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'guru-rina', child: Text('Ustazah Rina . Matematika')),
              DropdownMenuItem(value: 'guru-dewi', child: Text('Ustazah Dewi . Biologi')),
            ],
            onChanged: (v) => setState(() => _teacher = v ?? _teacher),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _room,
            decoration: const InputDecoration(labelText: 'Ruang', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Ruang A', child: Text('Ruang A')),
              DropdownMenuItem(value: 'Ruang B', child: Text('Ruang B')),
              DropdownMenuItem(value: 'Ruang C', child: Text('Ruang C')),
            ],
            onChanged: (v) => setState(() => _room = v ?? _room),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.utc(2026, 1, 1),
                      lastDate: DateTime.utc(2027, 12, 31),
                      initialDate: _day,
                    );
                    if (d != null) setState(() => _day = DateTime.utc(d.year, d.month, d.day));
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text('${_day.day}/${_day.month}/${_day.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: _start);
                    if (t != null) setState(() => _start = t);
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text('${_start.hour}:${_start.minute.toString().padLeft(2, '0')}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _dur,
            decoration: const InputDecoration(labelText: 'Durasi (menit)', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 60, child: Text('60 menit')),
              DropdownMenuItem(value: 90, child: Text('90 menit standar')),
              DropdownMenuItem(value: 120, child: Text('120 menit')),
            ],
            onChanged: (v) => setState(() => _dur = v ?? 90),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
                labelText: 'Catatan', hintText: 'Contoh: Bawa buku latihan bab 3'),
          ),
          const SizedBox(height: 8),
          if (_conflict != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(10)),
              child: Text(_conflict!, style: const TextStyle(color: Color(0xFFC62828))),
            ),
          OutlinedButton.icon(
            onPressed: _checkConflict,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Cek Bentrok Dulu'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      // Konversi WIB yang dipilih ke UTC: WIB = UTC+7.
                      final startWib = DateTime(_day.year, _day.month, _day.day, _start.hour, _start.minute);
                      final startUtc = startWib.subtract(const Duration(hours: 7));
                      final endUtc = startUtc.add(Duration(minutes: _dur));
                      final repo = SessionLocalRepo(ref.read(appDbProvider));
                      if (widget.sessionId == null) {
                        await repo.create(
                          subject: _subject.text,
                          teacherId: _teacher,
                          startUtc: startUtc,
                          endUtc: endUtc,
                          room: _room,
                          note: _note.text,
                        );
                      } else {
                        await repo.updateTime(
                          id: widget.sessionId!,
                          startUtc: startUtc,
                          endUtc: endUtc,
                          room: _room,
                        );
                      }
                      ref.invalidate(weekSessionsProvider);
                      await AlarmResync(ref.read(appDbProvider), AlarmService()).run();
                      AppLog.record('session_save', _subject.text);
                      if (!context.mounted) return;
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Jadwal tersimpan. Alarm ikut disesuaikan.')));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: Text(_saving ? 'Menyimpan...' : 'Simpan Jadwal'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aturan: guru dan ruang yang bentrok pada rentang yang sama otomatis ditolak. Sesi berakhir tepat saat sesi lain mulai tidak dianggap bentrok.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
