// Tab Saya: profil aktif dengan foto, tagihan, alarm, sync paket, backup. Semua lokal.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/alarm/alarm_service.dart';
import '../../core/log/app_log.dart';
import '../../data/local/les_store.dart';
import '../../data/local/parent_link.dart';
import '../auth/active_profile.dart';
import '../teacher/photo_service.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});
  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  String? _linkCode;
  final _claim = TextEditingController();

  @override
  void dispose() {
    _claim.dispose();
    super.dispose();
  }

  Future<void> _changePhoto(String profileId) async {
    try {
      final path = await PhotoService().takeProfilePhoto();
      await ref.read(lesStoreProvider).updatePhoto(profileId, path);
      ref.invalidate(activeProfileProvider);
      AppLog.record('photo_change', profileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil terpasang otomatis.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeProfileProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Akun Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          active.when(
            loading: () => const Card(child: ListTile(title: Text('Memuat profil...'))),
            error: (e, _) => Card(child: ListTile(title: Text('Gagal: $e'))),
            data: (p) {
              final photo = p?.photoPath;
              final hasPhoto = photo != null &&
                  photo.isNotEmpty &&
                  File(photo).existsSync();
              return Card(
                child: ListTile(
                  leading: hasPhoto
                      ? CircleAvatar(backgroundImage: FileImage(File(photo)))
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('${p?.name ?? '-'} . ${p?.role ?? '-'}'),
                  subtitle: Text(p?.subject != null && (p?.subject ?? '').isNotEmpty
                      ? '${p?.subject} . PIN aktif'
                      : 'PIN aktif'),
                  trailing: TextButton(
                    onPressed: p == null ? null : () => _changePhoto(p.id),
                    child: const Text('Ganti Foto'),
                  ),
                ),
              );
            },
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.family_restroom_outlined),
                  title: const Text('Tautan Ortu dan Anak'),
                  subtitle: Text(_linkCode == null
                      ? 'Buat kode 6 digit, berlaku 24 jam. Maks 2 ortu per anak.'
                      : 'Kode anak: $_linkCode . Berlaku 24 jam.'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final code =
                          await ParentLinkService().createForChild('sinta-id');
                      setState(() => _linkCode = code);
                    },
                    child: const Text('Buat Kode'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _claim,
                          decoration: const InputDecoration(
                            labelText: 'Klaim kode anak',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final child = await ParentLinkService()
                              .claim(code: _claim.text, parentId: 'ortu-ibu');
                          final msg = child == null
                              ? 'Kode tidak valid, kedaluwarsa, atau batas tautan tercapai (maks 2 ortu per anak).'
                              : 'Tertaut ke anak: $child. Hanya bisa baca.';
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text(msg)));
                        },
                        child: const Text('Klaim'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text('Tes Alarm'),
                  subtitle: const Text(
                      'Pastikan bunyi keluar sebelum hari H. Tes info dan urgent.'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => AlarmService().test('info'),
                        child: const Text('Info'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => AlarmService().test('urgent'),
                        child: const Text('Urgent'),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.battery_saver_outlined),
                  title: const Text('Izin dan Baterai'),
                  subtitle: const Text(
                      'Xiaomi Autostart. Samsung Unrestricted. Oppo Vivo background allow.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => AlarmService().openSettings(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Tagihan Les'),
                  subtitle: const Text('SPP Okt 2026 . Buat, bukti, verifikasi, kwitansi.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/bills'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync dan Backup'),
                  subtitle: const Text('Distribusi JSON, backup ZIP, riwayat jelas.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/sync'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
