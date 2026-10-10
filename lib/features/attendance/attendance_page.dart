// Provider absensi dan halaman rekap per sesi F5.2.
// Tombol guru: Tampilkan Kode dan Check In. Tombol siswa: Pindai.
// Admin: Ekspor CSV dan Jalankan Auto Alpa.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/les_store.dart';
import 'attendance_repo.dart';
import 'export_service.dart';

final attendanceRepoProvider = Provider((ref) => AttendanceRepo(ref.watch(appDbProvider)));
final exportProvider = Provider((ref) => ExportService(ref.watch(appDbProvider)));

class AttendancePage extends ConsumerWidget {
  final String sessionId;
  const AttendancePage({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(attendanceRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Sesi')),
      body: FutureBuilder(
        future: repo.bySession(sessionId),
        builder: (c, snap) {
          final list = snap.data ?? [];
          final hadir = list.where((e) => e.status == 'hadir').length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: Text('Hadir: $hadir dari ${list.length} catatan'),
                  subtitle: const Text('Izin dan sakit tidak dihitung alpa.'),
                  trailing: TextButton(
                    onPressed: () async {
                      final f = await ref.read(exportProvider).attendanceCsv(sessionId: sessionId);
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
                      onPressed: () => context.push('/attendance/$sessionId/qr'),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Kode Guru'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/attendance/$sessionId/scan'),
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final n = await repo.autoAlpa();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Auto alpa jalan. $n sesi ditandai.')));
                },
                icon: const Icon(Icons.auto_mode_outlined),
                label: const Text('Jalankan Auto Alpa H+30'),
              ),
            ],
          );
        },
      ),
    );
  }
}
