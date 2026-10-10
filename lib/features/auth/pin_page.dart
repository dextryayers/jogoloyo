// PIN 6 kotak untuk ganti profil di HP bersama. Maks 5 salah lalu kunci 5 menit.
import 'package:flutter/material.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});
  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final _c = TextEditingController();
  int _wrong = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masukkan PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih profil: Sinta (Siswa)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _c,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: 'PIN 6 digit', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_c.text.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN harus 6 digit.')));
                  return;
                }
                setState(() => _wrong++);
                if (_wrong >= 5) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Terkunci 5 menit. Coba lagi pukul sesuai info.')));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN salah. Cek lagi.')));
              },
              child: const Text('Masuk'),
            ),
            const SizedBox(height: 8),
            const Text('Lupa PIN: minta reset ke owner dengan PIN owner.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
