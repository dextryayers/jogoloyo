// Tab Guru F4 deep: daftar ACTIVE plus badge antrian.
// Foto asli dari file lokal. Tanpa avatar generik untuk yang sudah ACTIVE.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import 'teacher_providers.dart';

class TeacherTab extends ConsumerWidget {
  const TeacherTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gurus = ref.watch(guruListProvider);
    final pending = ref.watch(pendingVerifProvider);
    final pendingCount = pending.valueOrNull?.length ?? 0;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(guruListProvider);
          ref.invalidate(pendingVerifProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Guru Jogoloyo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Hanya guru Terverifikasi yang bisa dijadwalkan. Foto diperiksa manusia, bukan AI.',
                style: TextStyle(color: JogloColors.muted)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Stack(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: JogloColors.primary, size: 28),
                    if (pendingCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: JogloColors.danger, shape: BoxShape.circle),
                          child: Text('$pendingCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
                title: Text('Antrian Review (Admin): $pendingCount menunggu'),
                subtitle: const Text('Maks 1x24 jam. Alasan tolak wajib jelas.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/teachers/review'),
              ),
            ),
            const SizedBox(height: 8),
            gurus.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Gagal: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('Belum ada guru.'),
                      subtitle: Text('Tambah via tombol di bawah lalu ajukan verifikasi.'),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final g in list)
                      _GuruCard(id: g.id, name: g.name, subject: g.subject ?? 'Mapel belum diisi', photo: g.photoPath),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/teachers/submit'),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Daftar Guru'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/teachers/review'),
                    icon: const Icon(Icons.inbox_outlined),
                    label: const Text('Buka Antrian'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuruCard extends ConsumerWidget {
  final String id;
  final String name;
  final String subject;
  final String? photo;
  const _GuruCard({required this.id, required this.name, required this.subject, this.photo});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(teacherRepoProvider);
    return Card(
      child: ListTile(
        leading: photo != null && photo!.isNotEmpty && File(photo!).existsSync()
            ? CircleAvatar(backgroundImage: FileImage(File(photo!)))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name),
        subtitle: Text(subject),
        trailing: FutureBuilder(
          future: repo.byTeacher(id),
          builder: (c, snap) {
            final st = snap.data?.status ?? 'DRAFT';
            if (st == 'ACTIVE') {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: JogloColors.scheduledBg, borderRadius: BorderRadius.circular(999)),
                child: const Text('Terverifikasi',
                    style: TextStyle(color: JogloColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w700)),
              );
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: JogloColors.izinBg, borderRadius: BorderRadius.circular(999)),
              child: Text(st == 'REJECTED' ? 'Ditolak' : st == 'SUSPENDED' ? 'Suspend' : 'Menunggu',
                  style: const TextStyle(color: JogloColors.warning, fontSize: 12, fontWeight: FontWeight.w700)),
            );
          },
        ),
        onTap: () => context.push('/teachers/$id'),
      ),
    );
  }
}
