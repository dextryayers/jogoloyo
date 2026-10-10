// Tugas detail F6.2: kumpul file 10 MB, label terlambat otomatis, nilai guru.
// Beda HP via paket setoran? V.01.0: kumpul di HP yang sama atau via file manual.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/time/wib.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';
import 'learn_providers.dart';

class AssignmentPage extends ConsumerWidget {
  final String assignmentId;
  const AssignmentPage({super.key, required this.assignmentId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tugas')),
      body: FutureBuilder<Assignment?>(
        future: (db.select(db.assignments)..where((t) => t.id.equals(assignmentId))).getSingleOrNull(),
        builder: (c, snap) {
          final a = snap.data;
          if (a == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(a.desc),
                      const SizedBox(height: 8),
                      Text('Tenggat: ${Wib.dmy(a.dueUtc)} ${Wib.hm(a.dueUtc)}'),
                      Text('Nilai maks: ${a.maxScore}'),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(learningStoreProvider).submitAssignment(assignmentId: a.id, studentId: 'siswa-sinta');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terkumpul. Telat ditandai otomatis jika lewat tenggat.')));
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Kumpulkan File (maks 10 MB)'),
              ),
              const Text('Bisa kumpul ulang sebelum tenggat. Versi terakhir yang dinilai.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          );
        },
      ),
    );
  }
}
