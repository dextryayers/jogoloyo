// Editor catatan: judul besar tanpa garis, isi lega, hitung kata live,
// tanggal update, simpan besar di bawah, hapus via menu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/local/simple_store.dart';
import 'note_export_sheet.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  final String? noteId;
  const NoteEditorPage({super.key, this.noteId});
  @override
  ConsumerState<NoteEditorPage> createState() => _State();
}

class _State extends ConsumerState<NoteEditorPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _ready = false;
  bool _saved = false;
  String? _id;
  DateTime? _updated;
  int _words = 0;

  @override
  void initState() {
    super.initState();
    _id = widget.noteId;
    _body.addListener(_count);
    _load();
  }

  void _count() {
    final t = _body.text.trim();
    final w = t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
    if (w != _words && mounted) setState(() => _words = w);
  }

  Future<void> _load() async {
    if (widget.noteId != null) {
      final all = await ref.read(simpleStoreProvider).loadNotes();
      final n = all.where((e) => e.id == widget.noteId).firstOrNull;
     if (n != null) {
         _id = n.id;
         _title.text = n.title;
         _body.text = n.body;
         _updated = n.updatedAt;
       } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catatan tidak ditemukan. Mungkin sudah dihapus.')));
        context.pop();
        return;
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  // Autosave: bila keluar tanpa tekan Simpan dan ada isi, simpan diam diam.
  // Dijamin tidak ada tulisan hilang.
  Future<void> _autoSave() async {
    if (_saved) return;
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) return;
    final nid = await ref.read(simpleStoreProvider).saveNote(
          id: _id,
          title: _title.text,
          body: _body.text,
        );
    _id = nid;
    _updated = DateTime.now().toUtc();
    ref.invalidate(notesProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
          appBar: AppBar(title: const Text('Catatan')),
          body: const Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _autoSave();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'Catatan Baru' : 'Ubah Catatan'),
        actions: [
          IconButton(
            tooltip: 'Ekspor gambar atau PDF',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => NoteExportSheet(
                title: _title.text,
                body: _body.text,
                date: _updated == null ? 'Baru' : _date(_updated!),
              ),
            ),
          ),
          if (widget.noteId != null)
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline, color: JogloColors.danger),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Hapus catatan'),
                    content: const Text('Catatan ini dihapus dari HP.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
                      ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Hapus')),
                    ],
                  ),
                );
                if (ok != true) return;
                await ref.read(simpleStoreProvider).deleteNote(widget.noteId!);
                ref.invalidate(notesProvider);
                if (!context.mounted) return;
                context.pop();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    hintText: 'Judul',
                    hintStyle: TextStyle(color: JogloColors.muted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                if (_updated != null)
                  Text(_date(_updated!),
                      style: const TextStyle(fontSize: 12, color: JogloColors.muted)),
                const Divider(),
                TextField(
                  controller: _body,
                  maxLines: null,
                  autofocus: widget.noteId == null,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                  decoration: const InputDecoration(
                    hintText: 'Tulis di sini...',
                    hintStyle: TextStyle(color: JogloColors.muted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: JogloColors.line)),
            ),
            child: Row(
              children: [
                Text('$_words kata', style: const TextStyle(color: JogloColors.muted)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Isi dulu judul atau isinya.')));
                      return;
                    }
                     final nid = await ref.read(simpleStoreProvider).saveNote(
                           id: _id,
                           title: _title.text,
                           body: _body.text,
                         );
                     _id = nid;
                     _saved = true;
                     _updated = DateTime.now().toUtc();
                     ref.invalidate(notesProvider);
                    if (!context.mounted) return;
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Catatan tersimpan di HP ini.')));
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _date(DateTime utc) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final w = utc.toUtc().add(const Duration(hours: 7));
    return 'Terakhir ${w.day} ${months[w.month]} ${w.year} ${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')} WIB';
  }
}
