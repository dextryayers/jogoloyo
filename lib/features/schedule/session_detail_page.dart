// Detail sesi F2.1: info penuh plus aksi Alarm, Izin, Edit dan Batal untuk admin.
// Semua tombol min 48 dp. Copy spesifik, tanpa karakter terlarang.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../core/time/wib.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';
import '../../data/local/session_local_repo.dart';
import 'alarm_prefs.dart';
import 'alarm_sheet.dart';
import 'leave_sheet.dart';
import 'schedule_providers.dart';

class SessionDetailPage extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionDetailPage({super.key, required this.sessionId});
  @override
  ConsumerState<SessionDetailPage> createState() => _State();
}

class _State extends ConsumerState<SessionDetailPage> {
  @override
  Widget build(BuildContext context) {
    final repo = SessionLocalRepo(ref.watch(appDbProvider));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Sesi')),
      body: FutureBuilder<Session?>(
        future: repo.byId(widget.sessionId),
        builder: (c, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snap.data;
          if (s == null) {
            return const Center(child: Text('Sesi tidak ditemukan. Mungkin sudah dihapus.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.subject,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(Wib.range(s.startUtc, s.endUtc),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(Wib.dmy(s.startUtc),
                          style: const TextStyle(color: JogloColors.muted)),
                      const SizedBox(height: 8),
                      Text('Ruang: ${s.room}'),
                      if (s.note.isNotEmpty) Text('Catatan: ${s.note}'),
                      Text('Status: ${s.status} . Revisi ${s.revision}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder(
                future: AlarmPrefs.load(s.id, 'siswa-sinta'),
                builder: (cc, ap) {
                  final offs = ap.data?.offsets ?? [30, 10];
                  final on = ap.data?.enabled ?? true;
                  return Card(
                    child: ListTile(
                      leading: Icon(on ? Icons.alarm_on : Icons.alarm_off,
                          color: on ? JogloColors.primary : JogloColors.muted),
                      title: Text(on
                          ? 'Alarm aktif: ${offs.map((e) => 'H-$e').join(', ')}'
                          : 'Alarm mati untuk sesi ini.'),
                      subtitle: const Text('Bunyi walau app ditutup. Tes dulu sebelum hari H.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AlarmSheet(session: s),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => LeaveSheet(sessionId: s.id),
                      ),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Izin atau Sakit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await AlarmService().test('info');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Tes terkirim. Cek bunyi dan getar HP.'
                                : 'Tes gagal. Cek izin notifikasi.')));
                      },
                      icon: const Icon(Icons.volume_up_outlined),
                      label: const Text('Tes Bunyi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.groups_outlined, color: JogloColors.primary),
                      title: const Text('Absensi dan QR'),
                      subtitle: const Text('Guru tampilkan kode, siswa pindai di kelas.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/attendance/${s.id}'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.login_outlined, color: JogloColors.primary),
                      title: const Text('Check In Guru'),
                      subtitle: const Text('Wajib centang kepatuhan berjilbab.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/checkin/${s.id}/${s.teacherId}'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Ubah jam atau ruang'),
                      subtitle: const Text('Bentrok guru atau ruang akan ditolak otomatis.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/schedule/${s.id}/edit'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cancel_outlined, color: JogloColors.danger),
                      title: const Text('Batalkan sesi',
                          style: TextStyle(color: JogloColors.danger)),
                      subtitle: const Text('Butuh alasan min 10 karakter. Alarm ikut batal.'),
                      onTap: () => _cancel(context, ref, s),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, Session s) async {
    final c = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Batalkan sesi'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'Alasan batal',
            hintText: 'Contoh: Ruang A dipakai ujian sekolah.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Tidak')),
          ElevatedButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Batalkan')),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await SessionLocalRepo(ref.read(appDbProvider))
          .cancel(id: s.id, reason: reason);
      await AlarmService().cancel(s.id, 'siswa-sinta');
      ref.invalidate(weekSessionsProvider);
      if (!context.mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi dibatalkan. Alarm ikut dibatalkan.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
