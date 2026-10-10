// Setup guru pertama: input nama, mapel, lalu foto kamera autosave lokal.
// Foto langsung tersimpan di HP saat diambil, bukan saat tombol simpan.
// Setelah simpan, profil aktif terpasang dan masuk dashboard utama.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/log/app_log.dart';
import '../../data/local/les_store.dart';
import '../../shared/widgets/app_logo.dart';
import '../teacher/photo_service.dart';
import '../teacher/teacher_providers.dart';
import 'active_profile.dart';

class GuruSetupPage extends ConsumerStatefulWidget {
  const GuruSetupPage({super.key});
  @override
  ConsumerState<GuruSetupPage> createState() => _State();
}

class _State extends ConsumerState<GuruSetupPage> {
  final _name = TextEditingController();
  String _subject = 'Matematika';
  String _gender = 'P';
  String? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('pending_guru_photo');
    if (saved != null && mounted) setState(() => _photo = saved);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final path = await PhotoService().takeProfilePhoto();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_guru_photo', path);
      if (!mounted) return;
      setState(() => _photo = path);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto tersimpan otomatis di HP ini.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e Jika kamera tidak tersedia, lanjut tanpa foto lalu pasang di menu Saya.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Guru')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: AppLogo(size: 72)),
          const SizedBox(height: 8),
          const Text('Siapa yang mengajar?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          const Text('Isi nama guru. Foto diambil via kamera dan langsung tersimpan otomatis.',
              textAlign: TextAlign.center, style: TextStyle(color: JogloColors.muted)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nama guru',
              hintText: 'Contoh: Ustazah Rina',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _subject,
            decoration: const InputDecoration(labelText: 'Mapel'),
            items: const [
              DropdownMenuItem(value: 'Matematika', child: Text('Matematika')),
              DropdownMenuItem(value: 'Biologi', child: Text('Biologi')),
              DropdownMenuItem(value: 'Fisika', child: Text('Fisika')),
            ],
            onChanged: (v) => setState(() => _subject = v ?? _subject),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const [
              DropdownMenuItem(value: 'P', child: Text('Perempuan (wajib verifikasi jilbab)')),
              DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
            ],
            onChanged: (v) => setState(() => _gender = v ?? _gender),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: JogloColors.primary),
              title: Text(_photo == null ? 'Ambil Foto Profil' : 'Foto terpasang otomatis'),
              subtitle: Text(_photo == null
                  ? 'Wajib kamera. Hasil langsung autosave di HP.'
                  : 'Ketuk untuk ambil ulang.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _takePhoto,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_name.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Isi nama guru dulu.')));
                        return;
                      }
                      setState(() => _saving = true);
                      try {
                        final store = ref.read(lesStoreProvider);
                        final id = await store.createAccount(
                          role: 'GURU',
                          name: _name.text,
                          pin: '123456',
                          gender: _gender,
                          subject: _subject,
                        );
                        final photo = _photo ?? '';
                        if (photo.isNotEmpty) {
                          await store.updatePhoto(id, photo);
                        }
                        try {
                          await ref.read(teacherRepoProvider).submit(
                                teacherId: id,
                                photoPath: photo,
                                idDocPath: photo,
                              );
                        } catch (_) {}
                        await setActiveProfile(id);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('guru_setup_done', true);
                        await prefs.setBool('onboarding_done', true);
                        await prefs.remove('pending_guru_photo');
                        AppLog.record('guru_setup', id);
                        if (!context.mounted) return;
                        context.go('/home');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Selamat datang. Foto profil terpasang di menu Saya.')));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Menyimpan...' : 'Simpan dan Masuk Dashboard'),
            ),
          ),
          const SizedBox(height: 8),
          const Text('PIN awal 123456. Ganti di menu Saya setelah masuk.',
              style: TextStyle(fontSize: 12, color: JogloColors.muted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
