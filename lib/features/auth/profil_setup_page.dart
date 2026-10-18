// Setup profil: nama plus foto kamera autosave plus slot jam plus gender.
// Foto langsung tersimpan di HP saat diambil.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/log/app_log.dart';
import '../../shared/widgets/app_logo.dart';
import '../teacher/photo_service.dart';

class ProfilSetupPage extends StatefulWidget {
  const ProfilSetupPage({super.key});
  @override
  State<ProfilSetupPage> createState() => _State();
}

class _State extends State<ProfilSetupPage> {
  final _name = TextEditingController();
  String _gender = 'Perempuan';
  String? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name.text = p.getString('user_name') ?? '';
      _gender = p.getString('user_gender') ?? 'Perempuan';
      _photo = p.getString('user_photo');
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final path = await PhotoService().takeProfilePhoto();
      final p = await SharedPreferences.getInstance();
      await p.setString('user_photo', path);
      if (!mounted) return;
      setState(() => _photo = path);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto tersimpan otomatis di HP ini.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e Bisa lanjut tanpa foto.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Kamu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: AppLogo(size: 64)),
          const SizedBox(height: 8),
          const Text('Kenalan dulu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama', hintText: 'Contoh: Ustazah Rina'),
          ),
const SizedBox(height: 12),
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: [
              for (final g in ['Perempuan', 'Laki-laki'])
                ChoiceChip(
                  label: Text(g),
                  selected: _gender == g,
                  onSelected: (_) => setState(() => _gender = g),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: (_photo != null && File(_photo!).existsSync())
                  ? CircleAvatar(radius: 24, backgroundImage: FileImage(File(_photo!)))
                  : const CircleAvatar(radius: 24, child: Icon(Icons.person)),
              title: Text(_photo == null ? 'Ambil Foto Profil' : 'Foto terpasang otomatis'),
              subtitle: const Text('Via kamera. Langsung autosave di HP.'),
              trailing: const Icon(Icons.camera_alt_outlined),
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
                            const SnackBar(content: Text('Isi nama dulu.')));
                        return;
                      }
                      setState(() => _saving = true);
                      final p = await SharedPreferences.getInstance();
await p.setString('user_name', _name.text.trim());
                       await p.setString('user_gender', _gender);
                       await p.setBool('profil_done', true);
                       AppLog.record('profil_setup', _gender);
                      if (!context.mounted) return;
                      context.go('/notif-setup');
                    },
              child: Text(_saving ? 'Menyimpan...' : 'Lanjut Atur Notifikasi'),
            ),
          ),
        ],
      ),
    );
  }
}
