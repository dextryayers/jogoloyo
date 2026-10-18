// Tab Profil: kartu profil berfoto plus jalan ke ubah profil dan waktu.
// Tanpa kode PIN. Simpel.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/log/app_log.dart';
import '../../data/local/les_store.dart';
import '../auth/active_profile.dart';
import '../teacher/photo_service.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});
  @override
  ConsumerState<ProfileTab> createState() => _State();
}

class _State extends ConsumerState<ProfileTab> {
  Future<void> _changePhoto() async {
    final active = await ref.read(activeProfileProvider.future);
    try {
      final path = await PhotoService().takeProfilePhoto();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_photo', path);
      if (active != null) {
        await ref.read(lesStoreProvider).updatePhoto(active.id, path);
        ref.invalidate(activeProfileProvider);
      }
      AppLog.record('photo_change', active?.id ?? 'prefs');
      if (!mounted) return;
      setState(() {});
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
          const Text('Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (c, snap) {
              final p = snap.data;
              final name = p?.getString('user_name') ?? active.valueOrNull?.name ?? '-';
              final gender = p?.getString('user_gender') ?? '-';
              final photo = p?.getString('user_photo') ?? active.valueOrNull?.photoPath;
              final hasPhoto = photo != null && photo.isNotEmpty && File(photo).existsSync();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      hasPhoto
                          ? CircleAvatar(radius: 40, backgroundImage: FileImage(File(photo)))
                          : const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                      const SizedBox(height: 8),
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(gender),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _changePhoto,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Ganti Foto'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/profil-setup'),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Ubah'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Ubah Waktu Notifikasi'),
              subtitle: const Text('Jam tiap slot plus suara.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/notif-setup'),
            ),
          ),
        ],
      ),
    );
  }
}
