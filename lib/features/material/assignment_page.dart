// Tugas detail F6.2: kumpul file 10 MB, label terlambat otomatis, nilai guru.
// Beda HP via paket setoran? V.01.0: kumpul di HP yang sama atau via file manual.
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/time/wib.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';
import 'learn_providers.dart';

int _penalty(DateTime dueUtc, DateTime submittedAt) {
  if (!submittedAt.toUtc().isAfter(dueUtc.toUtc())) return 0;
  final days = submittedAt.toUtc().difference(dueUtc.toUtc()).inDays + 1;
  return (days * 10).clamp(0, 30);
}

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
              const Text('Aturan telat: potongan 10 persen per hari, maks 3 hari. Lewat 3 hari tetap dinilai 0 kecuali izin guru.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text('Hasil kumpul', style: TextStyle(fontWeight: FontWeight.w800)),
              FutureBuilder(
                future: (db.select(db.submissions)..where((t) => t.assignmentId.equals(a.id))..orderBy([(t) => OrderingTerm(expression: t.submittedAt, mode: OrderingMode.desc)])).get(),
                builder: (cc, ssnap) {
                  final subs = ssnap.data ?? [];
                  if (subs.isEmpty) return const Card(child: ListTile(title: Text('Belum ada yang kumpul.')));
                  return Column(
                    children: [
                      for (final s in subs.take(10))
                        Card(
                          child: ListTile(
                            leading: Icon(s.status == 'terlambat' ? Icons.warning_outlined : Icons.check_circle_outline),
                            title: Text('${s.studentId} . ${s.status} . Nilai: ${s.score ?? '-'}'),
                            subtitle: Text('${s.submittedAt} . Potongan: ${_penalty(a.dueUtc, s.submittedAt)} persen'),
                            trailing: s.score == null
                                ? TextButton(
                                    onPressed: () async {
                                      await ref.read(learningStoreProvider).grade(s.id.toString(), a.maxScore);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dinilai penuh. Kurangi manual jika telat via ubah nilai di DB pada V.01.1.')));
                                    },
                                    child: const Text('Nilai'),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
