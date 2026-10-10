// Provider absensi dan halaman rekap per sesi F5 deep.
// Auto alpa jalan otomatis saat halaman dibuka plus tombol manual.
// Rekap bulan berjalan HISA untuk siswa-sinta tampil di atas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/log/app_log.dart';
import '../../data/local/les_store.dart';
import 'attendance_repo.dart';
import 'export_service.dart';

final attendanceRepoProvider = Provider((ref) => AttendanceRepo(ref.watch(appDbProvider)));
final exportProvider = Provider((ref) => ExportService(ref.watch(appDbProvider)));

class AttendancePage extends ConsumerStatefulWidget {
  final String sessionId;
  const AttendancePage({super.key, required this.sessionId});
  @override
  ConsumerState<AttendancePage> createState() => _State();
}

class _State extends ConsumerState<AttendancePage> {
  bool _autoDone = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final n = await ref.read(attendanceRepoProvider).autoAlpa();
      AppLog.record('auto_alpa', '$n');
      if (mounted) setState(() => _autoDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(attendanceRepoProvider);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Sesi')),
      body: FutureBuilder(
        future: Future.wait([repo.bySession(widget.sessionId), repo.recapMonth('siswa-sinta', now.year, now.month)]),
        builder: (c, snap) {
          final list = (snap.data?[0] as List?)?.cast() ?? [];
          final recap = (snap.data?[1] as Map<String, int>?) ?? {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0};
          final hadir = list.where((e) => e.status == 'hadir').length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text('Bulan ini H:${recap['hadir']} I:${recap['izin']} S:${recap['sakit']} A:${recap['alpa']}'),
                  subtitle: Text(_autoDone ? 'Auto alpa H+30 sudah jalan otomatis.' : 'Menjalankan auto alpa...'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: Text('Sesi ini hadir: $hadir dari ${list.length} catatan'),
                  subtitle: const Text('Izin dan sakit tidak dihitung alpa.'),
                  trailing: TextButton(
                    onPressed: () async {
                      final f = await ref.read(exportProvider).attendanceCsv(sessionId: widget.sessionId);
                      await ref.read(exportProvider).share(f);
                    },
                    child: const Text('CSV'),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/attendance/${widget.sessionId}/qr'),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Kode Guru'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/attendance/${widget.sessionId}/scan'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Pindai'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final a in list)
                Card(
                  child: ListTile(
                    leading: Icon(
                      a.status == 'hadir' ? Icons.check_circle : Icons.info_outline,
                      color: a.status == 'hadir' ? Colors.green : Colors.orange,
                    ),
                    title: Text('${a.profileId} . ${a.status}'),
                    subtitle: Text('Via ${a.method} . ${a.createdAt}'),
                  ),
                ),
              if (list.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Belum ada catatan.'),
                    subtitle: Text('Guru tampilkan kode, siswa pindai di kelas.'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
