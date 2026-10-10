// Lapor Masalah: tulis judul plus rincian, tersimpan di HP, bagikan ke admin.
// Lampirkan log diagnosis otomatis agar admin cepat paham.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme.dart';
import '../../core/log/app_log.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _State();
}

class _State extends State<ReportPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  List<Map<String, String>> _sent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('reports_v1');
    if (raw == null) return;
    if (!mounted) return;
    setState(() {
      _sent = (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map((e) => {
            'id': '${e['id']}',
            'title': '${e['title']}',
            'at': '${e['at']}',
          }).toList();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Isi judul dan rincian masalah dulu.')));
      return;
    }
    final log = await AppLog.dumpFile();
    final text =
        'Lapor Masalah Les Jogoloyo\nJudul: ${_title.text.trim()}\nRincian: ${_body.text.trim()}';
    await SharePlus.instance.share(ShareParams(
      files: [XFile(log.path)],
      text: text,
      subject: 'Lapor Masalah Les Jogoloyo',
    ));
    final p = await SharedPreferences.getInstance();
    final item = {
      'id': const Uuid().v4(),
      'title': _title.text.trim(),
      'at': DateTime.now().toUtc().add(const Duration(hours: 7)).toString(),
    };
    final next = [..._sent, item];
    await p.setString('reports_v1', jsonEncode(next));
    AppLog.record('report', item['id'] ?? '');
    if (!mounted) return;
    setState(() {
      _sent = next;
      _title.clear();
      _body.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan dibagikan plus log. Tersimpan di bawah.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Masalah')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Ceritakan masalahnya',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Text('Log diagnosis ikut terkirim otomatis.',
              style: TextStyle(color: JogloColors.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Judul', hintText: 'Contoh: Alarm tidak bunyi'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Rincian',
              hintText: 'Kapan terjadi, HP apa, langkah yang dilakukan...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Kirim Laporan'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Terkirim', style: TextStyle(fontWeight: FontWeight.w800)),
          if (_sent.isEmpty)
            const Card(child: ListTile(title: Text('Belum ada laporan.')))
          else
            for (final r in _sent.reversed)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.mark_email_read_outlined, color: JogloColors.primary),
                  title: Text(r['title'] ?? ''),
                  subtitle: Text('${r['at']}'),
                ),
              ),
        ],
      ),
    );
  }
}
