// Tab Materi F6 deep: materi nyata, tugas nyata, kuis nyata. Offline first.
// Tambah materi via file picker 25 MB. Tugas kumpul 10 MB. Kuis acak opsi.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import '../../app/theme.dart';
import '../../core/time/wib.dart';
import '../../shared/widgets/states.dart';
import 'learn_providers.dart';

class MaterialTab extends ConsumerWidget {
  const MaterialTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mats = ref.watch(materialsProvider);
    final assigns = ref.watch(assignmentsProvider);
    final quizzes = ref.watch(quizzesProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(materialsProvider);
          ref.invalidate(assignmentsProvider);
          ref.invalidate(quizzesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Materi dan Tugas',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: 'Tambah materi',
                  icon: const Icon(Icons.add_circle, color: JogloColors.primary),
                  onPressed: () => _addMaterial(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const OfflineBanner(),
            const SizedBox(height: 12),
            const Text('Materi', style: TextStyle(fontWeight: FontWeight.w800)),
            mats.when(
              loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Memuat...'))),
              error: (e, _) => Text('Gagal: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: 'Belum ada materi',
                    desc: 'Belum ada materi Biologi. Minta ke guru via thread tugas.',
                    actionLabel: 'Tambah Contoh',
                    onAction: () => _addMaterial(context, ref),
                  );
                }
                return Column(
                  children: [
                    const _StorageBar(),
                    for (final m in list.take(5))
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: JogloColors.danger),
                          title: Text('${m.subject}: ${m.title}'),
                          subtitle: Text('${(m.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB . Revisi ${m.revision}${m.important ? ' . Penting' : ''}'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => OpenFilex.open(m.pathOrUrl),
                          onLongPress: () => _deleteMaterial(context, ref, m.id),
                        ),
                      ),
                    const Text('Ketuk untuk buka. Tahan untuk hapus dengan konfirmasi.',
                        style: TextStyle(fontSize: 12, color: JogloColors.muted)),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const Text('Tugas', style: TextStyle(fontWeight: FontWeight.w800)),
            assigns.when(
              loading: () => const SizedBox(),
              error: (e, _) => Text('Gagal: $e'),
              data: (list) => Column(
                children: [
                  for (final a in list.take(3))
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment_outlined, color: JogloColors.primary),
                        title: Text(a.title),
                        subtitle: Text('Tenggat: ${Wib.dmy(a.dueUtc)} ${Wib.hm(a.dueUtc)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/assignments/${a.id}'),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _addAssignment(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Tugas Contoh'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Kuis', style: TextStyle(fontWeight: FontWeight.w800)),
            quizzes.when(
              loading: () => const SizedBox(),
              error: (e, _) => Text('Gagal: $e'),
              data: (list) => Column(
                children: [
                  for (final q in list)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.quiz_outlined, color: JogloColors.primary),
                        title: Text(q.title),
                        subtitle: Text('${q.subject} . ${q.durationMin} menit . 1 resmi + 1 latihan'),
                        trailing: ElevatedButton(
                          onPressed: () => context.push('/quiz/${q.id}'),
                          child: const Text('Mulai'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMaterial(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(learningStoreProvider).pickAndSaveMaterial(subject: 'Matematika', title: 'Bab 3 Persamaan Linear');
      ref.invalidate(materialsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Materi tersimpan di HP ini.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addAssignment(BuildContext context, WidgetRef ref) async {
    await ref.read(learningStoreProvider).createAssignment(
          subject: 'Matematika',
          title: '10 soal latihan bab 3',
          desc: 'Kerjakan di buku, foto, lalu kumpulkan.',
          dueUtc: DateTime.now().toUtc().add(const Duration(days: 2)),
        );
    ref.invalidate(assignmentsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tugas dibuat.')));
  }

  Future<void> _deleteMaterial(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus materi'),
        content: const Text('File dihapus dari HP ini. Tindakan tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(learningStoreProvider).deleteMaterial(id);
    ref.invalidate(materialsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Materi dihapus.')));
  }
}

class _StorageBar extends ConsumerWidget {
  const _StorageBar();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.watch(learningStoreProvider).storageBytes(),
      builder: (c, snap) {
        final b = snap.data ?? 0;
        final mb = b / 1024 / 1024;
        final pct = (mb / 500).clamp(0.0, 1.0);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Penyimpanan materi: ${mb.toStringAsFixed(1)} MB dari 500 MB'),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: pct),
                if (pct > 0.8)
                  const Text('Hampir penuh. Hapus materi lama yang tidak penting.',
                      style: TextStyle(color: JogloColors.warning, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
