// Tab Saya simpel: profil (foto, nama, slot, gender) plus setting sistem.
// Setting: suara default, mode keras, izin notifikasi, tes bunyi, ulang setup, reset.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../data/local/les_store.dart';
import '../auth/active_profile.dart';
import '../schedule/alarm_prefs.dart';
import '../teacher/photo_service.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});
  @override
  ConsumerState<ProfileTab> createState() => _State();
}

class _State extends ConsumerState<ProfileTab> {
  String _sound = 'suara1';
  bool _loud = true;
  bool _exact = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final perm = await AlarmService().permissions();
    if (!mounted) return;
    setState(() {
      _sound = p.getString('default_sound') ?? 'suara1';
      _loud = p.getBool('default_loud') ?? true;
      _exact = perm['exactAlarm'] ?? true;
    });
  }

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
          const Text('Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (c, snap) {
              final p = snap.data;
              final name = p?.getString('user_name') ?? active.valueOrNull?.name ?? '-';
              final slot = p?.getString('user_slot') ?? 'Pagi';
              final gender = p?.getString('user_gender') ?? '-';
              final photo = p?.getString('user_photo') ?? active.valueOrNull?.photoPath;
              final hasPhoto = photo != null && photo.isNotEmpty && File(photo).existsSync();
              return Card(
                child: ListTile(
                  leading: hasPhoto
                      ? CircleAvatar(radius: 24, backgroundImage: FileImage(File(photo)))
                      : const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                  title: Text(name),
                  subtitle: Text('Jam $slot . $gender'),
                  trailing: TextButton(
                    onPressed: _changePhoto,
                    child: const Text('Ganti Foto'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text('Setting Sistem', style: TextStyle(fontWeight: FontWeight.w800)),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(_exact ? Icons.check_circle : Icons.warning,
                      color: _exact ? JogloColors.success : JogloColors.warning),
                  title: Text(_exact ? 'Izin alarm presisi aktif' : 'Izin alarm presisi mati'),
                  subtitle: const Text('Harus aktif agar bunyi tepat menit.'),
                  trailing: TextButton(
                    onPressed: () async {
                      await AlarmService().openSettings();
                      _load();
                    },
                    child: const Text('Buka'),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Text('Suara default: '),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: [
                            for (final s in AlarmSound.options)
                              ChoiceChip(
                                label: Text(s.label),
                                selected: _sound == s.id,
                                onSelected: (_) async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('default_sound', s.id);
                                  setState(() => _sound = s.id);
                                  AlarmService().test('urgent', sound: s.id, loud: _loud);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  value: _loud,
                  onChanged: (v) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('default_loud', v);
                    setState(() => _loud = v);
                  },
                  title: const Text('Mode Keras 200 persen'),
                  subtitle: const Text('Volume dipaksa maksimal plus getar kuat.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text('Tes Bunyi Keras'),
                  subtitle: const Text('Dengar suara default sekarang.'),
                  trailing: ElevatedButton(
                    onPressed: () => AlarmService().test('urgent', sound: _sound, loud: _loud),
                    child: const Text('Tes'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Ubah Profil'),
                  subtitle: const Text('Nama, foto, jam, gender.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profil-setup'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Ubah Waktu Notifikasi'),
                  subtitle: const Text('Jam tiap slot plus suara.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notif-setup'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: JogloColors.danger),
                  title: const Text('Reset Semua', style: TextStyle(color: JogloColors.danger)),
                  subtitle: const Text('Hapus profil, pengingat, catatan. Mulai dari awal.'),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: const Text('Reset semua'),
                        content: const Text('Semua data di HP ini dihapus. Lanjut?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
                          ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Reset')),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (!context.mounted) return;
                    context.go('/onboarding');
                  },
                ),
              ],
            ),
          ),
          const Center(
            child: Text('Les Jogoloyo V.02 simpel . 100 persen offline',
                style: TextStyle(fontSize: 12, color: JogloColors.muted)),
          ),
        ],
      ),
    );
  }
}
