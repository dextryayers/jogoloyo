// Detail guru plus review admin. Foto besar, alasan jelas, audit tercatat.
// Aksi sensitif butuh PIN owner? V.01.0 cukup PIN admin via dialog konfirmasi.
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';
import 'teacher_providers.dart';
import 'teacher_repo.dart';

class TeacherDetailPage extends ConsumerStatefulWidget {
  final String teacherId;
  const TeacherDetailPage({super.key, required this.teacherId});
  @override
  ConsumerState<TeacherDetailPage> createState() => _State();
}

class _State extends ConsumerState<TeacherDetailPage> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDbProvider);
    final repo = ref.watch(teacherRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Guru')),
      body: FutureBuilder<Profile?>(
        future: (db.select(db.profiles)..where((t) => t.id.equals(widget.teacherId))).getSingleOrNull(),
        builder: (c, snap) {
          final p = snap.data;
          if (p == null) return const Center(child: CircularProgressIndicator());
          return FutureBuilder<TeacherVerif?>(
            future: repo.byTeacher(p.id),
            builder: (cc, vsnap) {
              final v = vsnap.data;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          (v != null && v.photoPath.isNotEmpty && File(v.photoPath).existsSync())
                              ? CircleAvatar(radius: 32, backgroundImage: FileImage(File(v.photoPath)))
                              : const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                Text(p.subject ?? 'Mapel belum diisi', style: const TextStyle(color: JogloColors.muted)),
                                Text('Status: ${v?.status ?? 'DRAFT'}'),
                                if (v?.reason != null && v!.reason!.isNotEmpty)
                                  Text('Alasan: ${v.reason}', style: const TextStyle(color: JogloColors.danger)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.check_circle_outlined, color: JogloColors.success),
                          title: const Text('Setujui'),
                          subtitle: const Text('Hanya jika foto jelas dan rambut tertutup.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            try {
                              if (v == null) return;
                              await repo.review(verifId: v.id, reviewerId: 'admin-budi', approve: true);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Guru disetujui. Bisa dijadwalkan.')));
                              setState(() {});
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.cancel_outlined, color: JogloColors.danger),
                          title: const Text('Tolak dengan alasan', style: TextStyle(color: JogloColors.danger)),
                          subtitle: const Text('Pilih alasan baku plus tulis min 10 karakter.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _reject(context, ref, v?.id),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.block_outlined),
                          title: const Text('Suspend sementara'),
                          subtitle: const Text('Sesi masa depan ditahan sampai review ulang.'),
                          onTap: () => _suspend(context, ref, p.id),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Foto identitas hanya untuk admin dan dibuka setelah PIN. Tidak tampil ke siswa.',
                      style: TextStyle(fontSize: 12, color: JogloColors.muted)),
                  const SizedBox(height: 12),
                  const Text('Riwayat verifikasi', style: TextStyle(fontWeight: FontWeight.w800)),
                  FutureBuilder(
                    future: v == null
                        ? Future.value(<VerifAudit>[])
                        : (db.select(db.verifAudits)..where((t) => t.verifId.equals(v.id))..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get(),
                    builder: (cc, hsnap) {
                      final h = hsnap.data ?? [];
                      if (h.isEmpty) return const Card(child: ListTile(title: Text('Belum ada riwayat.')));
                      return Card(
                        child: Column(
                          children: [
                            for (final a in h.take(5))
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.history_outlined, size: 20),
                                title: Text('${a.fromStatus ?? 'DRAFT'} ke ${a.toStatus}'),
                                subtitle: Text('${a.reason ?? '-'} . ${a.createdAt}'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String? verifId) async {
    if (verifId == null) return;
    String reason = 'Foto tidak jelas';
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Tolak pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: reason,
              items: [...TeacherRepo.reasons, 'Lainnya']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => reason = v ?? reason,
              decoration: const InputDecoration(labelText: 'Alasan baku', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(controller: c, decoration: const InputDecoration(labelText: 'Detail min 10 karakter', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Tolak')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teacherRepoProvider).review(
            verifId: verifId,
            reviewerId: 'admin-budi',
            approve: false,
            reason: '$reason. ${c.text}'.trim(),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditolak dengan alasan. Guru bisa unggah ulang.')));
      setState(() {});
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _suspend(BuildContext context, WidgetRef ref, String teacherId) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Suspend guru'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Alasan min 10 karakter', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Suspend')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teacherRepoProvider).suspend(teacherId: teacherId, actorId: 'admin-budi', reason: c.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guru disuspend. Sesi baru ditahan.')));
      setState(() {});
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
