// Form daftar guru F4.1: nama, mapel, gender, PIN, foto kamera wajib.
// Aturan: foto profil wajib kamera depan, identitas wajib kamera, kompresi otomatis.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/les_store.dart';
import 'photo_service.dart';
import 'teacher_providers.dart';

class TeacherSubmitPage extends ConsumerStatefulWidget {
  const TeacherSubmitPage({super.key});
  @override
  ConsumerState<TeacherSubmitPage> createState() => _State();
}

class _State extends ConsumerState<TeacherSubmitPage> {
  final _name = TextEditingController();
  String _subject = 'Matematika';
  String _gender = 'P';
  final _pin = TextEditingController(text: '123456');
  String? _photo;
  String? _idDoc;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Guru')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Guru perempuan wajib berjilbab pada foto dan saat mengajar. Foto diperiksa admin maks 1x24 jam.',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama lengkap', hintText: 'Contoh: Ustazah Rina', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _subject,
            decoration: const InputDecoration(labelText: 'Mapel', border: OutlineInputBorder()),
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
            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'P', child: Text('Perempuan (wajib verifikasi jilbab)')),
              DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
            ],
            onChanged: (v) => setState(() => _gender = v ?? _gender),
          ),
          const SizedBox(height: 12),
          TextField(controller: _pin, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration(labelText: 'PIN 6 digit', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final p = await PhotoService().takeProfilePhoto();
                      setState(() => _photo = p);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                  icon: Icon(_photo == null ? Icons.camera_alt_outlined : Icons.check_circle, color: _photo == null ? null : Colors.green),
                  label: Text(_photo == null ? 'Foto Profil' : 'Foto OK'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final p = await PhotoService().takeIdPhoto();
                      setState(() => _idDoc = p);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                  icon: Icon(_idDoc == null ? Icons.badge_outlined : Icons.check_circle, color: _idDoc == null ? null : Colors.green),
                  label: Text(_idDoc == null ? 'Foto KTP' : 'KTP OK'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Wajib kamera, bukan galeri. Maks 2 MB setelah kompresi. Buram ditolak otomatis.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_name.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nama dulu.')));
                      return;
                    }
                    if (_photo == null || _idDoc == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ambil kedua foto dulu via kamera.')));
                      return;
                    }
                    setState(() => _saving = true);
                    try {
                      final store = ref.read(lesStoreProvider);
                      final id = await store.createAccount(
                          role: 'GURU', name: _name.text, pin: _pin.text, gender: _gender, subject: _subject);
                      await ref.read(teacherRepoProvider).submit(teacherId: id, photoPath: _photo!, idDocPath: _idDoc!);
                      if (!context.mounted) return;
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Pengajuan terkirim. Tunggu review admin maks 1x24 jam.')));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: Text(_saving ? 'Mengirim...' : 'Kirim Pengajuan'),
          ),
        ],
      ),
    );
  }
}
