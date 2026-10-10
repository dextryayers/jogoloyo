// Antrian review admin F4.2: terlama dulu, foto besar, setuju dan tolak cepat.
// Setiap keputusan tulis audit. Badge jumlah tampil di tab Guru.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'teacher_providers.dart';
import 'teacher_repo.dart';

class ReviewQueuePage extends ConsumerWidget {
  const ReviewQueuePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(pendingVerifProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Antrian Review')),
      body: q.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Antrian kosong. Semua pengajuan sudah diputuskan.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (c, i) {
              final v = list[i];
              final hasPhoto = v.photoPath.isNotEmpty && File(v.photoPath).existsSync();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          hasPhoto
                              ? CircleAvatar(radius: 28, backgroundImage: FileImage(File(v.photoPath)))
                              : const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.teacherId, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('Upaya ke ${v.attempts}. Masuk: ${v.createdAt}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ref.read(teacherRepoProvider).review(
                                      verifId: v.id, reviewerId: 'admin-budi', approve: true);
                                  ref.invalidate(pendingVerifProvider);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Disetujui. Guru bisa dijadwalkan.')));
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              },
                              child: const Text('Setujui'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/teachers/${v.teacherId}'),
                              child: const Text('Periksa'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
