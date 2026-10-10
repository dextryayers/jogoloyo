// Hapus total F8.2: hapus DB, files, secure storage, alarm. Butuh PIN owner.
// Berbahaya. Konfirmasi ketik HAPUS plus PIN. Setelah ini app kembali ke setup awal.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/alarm/alarm_service.dart';
import '../../data/local/les_store.dart';

class WipePage extends ConsumerStatefulWidget {
  const WipePage({super.key});
  @override
  ConsumerState<WipePage> createState() => _State();
}

class _State extends ConsumerState<WipePage> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hapus Total')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.warning_outlined, color: Colors.red),
              title: Text('Tindakan permanen.'),
              subtitle: Text('Menghapus DB, foto, materi, alarm, dan kunci. Pastikan backup ZIP sudah di laptop.'),
            ),
          ),
          TextField(controller: _pin, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration(labelText: 'PIN owner', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _confirm, decoration: const InputDecoration(labelText: 'Ketik HAPUS untuk konfirmasi', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (_confirm.text.trim() != 'HAPUS') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ketik HAPUS persis huruf besar.')));
                return;
              }
              try {
                final store = ref.read(lesStoreProvider);
                final owners = await store.db.select(store.db.profiles).get();
                final owner = owners.firstWhere((e) => e.role == 'OWNER', orElse: () => owners.first);
                await BackupServicePin.check(store, owner.id, _pin.text);
                await AlarmService().cancel('all', 'siswa-sinta');
                final docs = await getApplicationDocumentsDirectory();
                final dbFile = File('${docs.path}/jogoloyo.db');
                if (await dbFile.exists()) await dbFile.delete();
                for (final d in ['teacher_photos', 'materi', 'tugas']) {
                  final dir = Directory('${docs.path}/$d');
                  if (await dir.exists()) await dir.delete(recursive: true);
                }
                await const FlutterSecureStorage().deleteAll();
                final p = await SharedPreferences.getInstance();
                await p.clear();
                if (!context.mounted) return;
                context.go('/setup');
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Hapus Semua Sekarang'),
          ),
        ],
      ),
    );
  }
}

class BackupServicePin {
  static Future<void> check(LesStore store, String ownerId, String pin) async {
    await store.verifyPin(ownerId, pin);
  }
}
