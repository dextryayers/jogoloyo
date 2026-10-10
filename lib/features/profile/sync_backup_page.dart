// Sync dan backup F7.3: ekspor distribusi JSON, import revisi menang, backup ZIP.
// Jujur ke pengguna: ringkasan updated dan skipped, konflik revision tampil.
// Backup pengingat 7 hari ada di Beranda via OfflineBanner.
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/backup_sync.dart';
import '../../data/local/les_store.dart';

final backupProvider = Provider((ref) => BackupService(ref.watch(appDbProvider)));
final distribusiProvider = Provider((ref) => DistribusiService(ref.watch(appDbProvider)));

class SyncBackupPage extends ConsumerStatefulWidget {
  const SyncBackupPage({super.key});
  @override
  ConsumerState<SyncBackupPage> createState() => _State();
}

class _State extends ConsumerState<SyncBackupPage> {
  String _log = 'Belum ada aktivitas sync pada sesi ini.';
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync dan Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Ekspor Distribusi'),
                  subtitle: const Text('200 sesi terbaru plus materi dan pengumuman. Via WA atau Bluetooth.'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final f = await ref.read(distribusiProvider).exportDistribusi();
                      await Share.shareXFiles([XFile(f.path)], text: 'Paket distribusi Jogoloyo');
                      setState(() => _log = 'Distribusi diekspor: ${f.path}');
                    },
                    child: const Text('Ekspor'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Impor Distribusi'),
                  subtitle: const Text('Revision besar menang. Duplikat tidak ganda.'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final r = await FilePicker.platform.pickFiles();
                      if (r == null) return;
                      final res = await ref.read(distribusiProvider).importDistribusi(File(r.files.single.path!));
                      setState(() => _log = 'Impor selesai: ${res.updated} diperbarui, ${res.skipped} dilewati. Alarm ikut disesuaikan.');
                    },
                    child: const Text('Impor'),
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup Sekarang'),
                  subtitle: const Text('ZIP berisi DB plus foto dan file. Simpan ke laptop.'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final f = await ref.read(backupProvider).backupNow();
                      await Share.shareXFiles([XFile(f.path)], text: 'Backup Les Jogoloyo. Simpan di 2 media.');
                      final p = await SharedPreferences.getInstance();
                      setState(() => _log = 'Backup selesai. Terakhir: ${p.getString('last_backup')}');
                    },
                    child: const Text('Backup'),
                  ),
                ),
                const Divider(height: 1),
                FutureBuilder(
                  future: SharedPreferences.getInstance(),
                  builder: (c, snap) {
                    final v = snap.data?.getString('last_backup') ?? 'belum pernah';
                    return ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: const Text('Backup terakhir'),
                      subtitle: Text(v),
                    );
                  },
                ),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pulihkan dari ZIP', style: TextStyle(fontWeight: FontWeight.w800)),
                  const Text('Butuh PIN owner. Menimpa data HP ini. Restart setelah selesai.'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pin,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(labelText: 'PIN owner'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
                        if (r == null) return;
                        final db = ref.read(appDbProvider);
                        final owners = await (db.select(db.profiles)..where((t) => t.role.equals('OWNER'))).get();
                        if (owners.isEmpty) throw Exception('Belum ada owner di HP ini.');
                        final msg = await ref.read(backupProvider).restoreFromZip(
                              zip: File(r.files.single.path!),
                              ownerId: owners.first.id,
                              pin: _pin.text,
                            );
                        setState(() => _log = msg);
                      } catch (e) {
                        setState(() => _log = 'Restore gagal: $e');
                      }
                    },
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Pilih ZIP dan Pulihkan'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_log),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Hapus Total (Jual HP)', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Butuh PIN owner plus ketik HAPUS.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/wipe'),
            ),
          ),
          const Text('Jika HP hilang, restore dari ZIP terakhir di HP baru lalu input manual selisihnya. Tulis jujur ini di panduan.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
