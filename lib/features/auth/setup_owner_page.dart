// Setup owner pertama kali. Membuat PIN owner dan kunci les 32 byte.
// Kunci simpan di secure storage. QR pairing tampil sekali 60 detik.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/les_store.dart';

class SetupOwnerPage extends ConsumerStatefulWidget {
  const SetupOwnerPage({super.key});
  @override
  ConsumerState<SetupOwnerPage> createState() => _SetupOwnerPageState();
}

class _SetupOwnerPageState extends ConsumerState<SetupOwnerPage> {
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Awal Les Jogoloyo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Langkah 1 dari 1: buat akun owner di HP ini.',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Owner memegang PIN utama dan kunci les. Simpan kartu PIN fisik di amplop. Jika hilang, data tidak bisa dipulihkan.'),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama owner', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'PIN 6 digit', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _pin2,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration:
                  const InputDecoration(labelText: 'Ulangi PIN', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (_name.text.trim().isEmpty) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('Isi nama owner dulu.')));
                return;
              }
              if (_pin.text != _pin2.text || _pin.text.length != 6) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('PIN harus 6 digit dan sama.')));
                return;
              }
              try {
                final store = ref.read(lesStoreProvider);
                await store.createOwner(name: _name.text, pin: _pin.text);
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(
                    content: Text('Owner dibuat lokal. Kunci les dibuat dan tersimpan aman.')));
                // ignore: use_build_context_synchronously
                context.go('/home');
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            child: const Text('Buat Owner dan Kunci Les'),
          ),
        ],
      ),
    );
  }
}
