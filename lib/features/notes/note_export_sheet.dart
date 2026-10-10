// Ekspor catatan: gambar PNG JPG JPEG plus PDF, simpan ke galeri.
// Pixel: Low 1x, Normal 2x, High 3x, XHigh 4x agar tidak burik.
// JPG Low q50, Normal q80, High q92, XHigh q100. PNG selalu tajam.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../../app/theme.dart';
import '../../shared/widgets/app_logo.dart';

class NoteExportSheet extends StatefulWidget {
  final String title;
  final String body;
  final String date;
  const NoteExportSheet({super.key, required this.title, required this.body, required this.date});

  @override
  State<NoteExportSheet> createState() => _State();
}

class _State extends State<NoteExportSheet> {
  final _key = GlobalKey();
  String _format = 'PNG';
  String _pixel = 'Normal';
  bool _saving = false;

  double get _ratio {
    switch (_pixel) {
      case 'Low':
        return 1;
      case 'High':
        return 3;
      case 'XHigh':
        return 4;
      default:
        return 2;
    }
  }

  int get _jpgQuality {
    switch (_pixel) {
      case 'Low':
        return 50;
      case 'High':
        return 92;
      case 'XHigh':
        return 100;
      default:
        return 80;
    }
  }

  Future<void> _saveImage() async {
    setState(() => _saving = true);
    try {
      final boundary = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Pratinjau belum siap.');
      final image = await boundary.toImage(pixelRatio: _ratio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw Exception('Gagal render gambar.');
      Uint8List bytes = png.buffer.asUint8List();
      var name = 'jogoloyo_${DateTime.now().millisecondsSinceEpoch}';
      if (_format != 'PNG') {
        final dec = img.decodePng(bytes);
        if (dec == null) throw Exception('Gagal encode gambar.');
        bytes = img.encodeJpg(dec, quality: _jpgQuality);
        name = '$name.jpg';
      } else {
        name = '$name.png';
      }
      final res = await ImageGallerySaver.saveImage(bytes, quality: 100, name: name);
      final ok = (res is Map && res['isSuccess'] == true) || res != null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Gambar tersimpan di galeri ($_format $_pixel).' : 'Gagal simpan. Coba lagi.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePdf() async {
    setState(() => _saving = true);
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          build: (c) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Les Jogoloyo', style: const pw.TextStyle(fontSize: 16)),
              pw.Text(widget.title.isEmpty ? '(Tanpa judul)' : widget.title,
                  style: const pw.TextStyle(fontSize: 22)),
              pw.Text(widget.date, style: const pw.TextStyle(fontSize: 11)),
              pw.Divider(),
              pw.Text(widget.body, style: const pw.TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
      final tmp = await getTemporaryDirectory();
      final f = File('${tmp.path}/jogoloyo_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await f.writeAsBytes(await doc.save());
      final res = await ImageGallerySaver.saveFile(f.path);
      final ok = (res is Map && res['isSuccess'] == true) || res != null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'PDF tersimpan di galeri.' : 'Gagal simpan PDF.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ekspor Catatan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              RepaintBoundary(
                key: _key,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          AppLogo(size: 36, radius: 10),
                          SizedBox(width: 8),
                          Text('Les Jogoloyo',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title.isEmpty ? '(Tanpa judul)' : widget.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(widget.date,
                          style: const TextStyle(fontSize: 12, color: JogloColors.muted)),
                      const SizedBox(height: 8),
                      Text(widget.body, style: const TextStyle(fontSize: 14, height: 1.6)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Format', style: TextStyle(fontWeight: FontWeight.w800)),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in ['PNG', 'JPG', 'JPEG', 'PDF'])
                    ChoiceChip(
                      label: Text(f),
                      selected: _format == f,
                      onSelected: (_) => setState(() => _format = f),
                    ),
                ],
              ),
              if (_format != 'PDF') ...[
                const SizedBox(height: 8),
                const Text('Pixel (ketajaman)', style: TextStyle(fontWeight: FontWeight.w800)),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final q in ['Low', 'Normal', 'High', 'XHigh'])
                      ChoiceChip(
                        label: Text(q),
                        selected: _pixel == q,
                        onSelected: (_) => setState(() => _pixel = q),
                      ),
                  ],
                ),
                const Text('XHigh paling tajam dan tidak burik. File lebih besar.',
                    style: TextStyle(fontSize: 12, color: JogloColors.muted)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : (_format == 'PDF' ? _savePdf : _saveImage),
                  icon: const Icon(Icons.save_alt_outlined),
                  label: Text(_saving
                      ? 'Menyimpan...'
                      : _format == 'PDF'
                          ? 'Simpan PDF ke Galeri'
                          : 'Simpan $_format $_pixel ke Galeri'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
