// Editor catatan: judul plus isi plus simpan plus hapus. Simpel dan cepat.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/local/simple_store.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.noteId != null) {
      final all = await ref.read(simpleStoreProvider).loadNotes();
      final n = all.where((e) => e.id == widget.noteId).firstOrNull;
      if (n != null) {
        _title.text = n.title;
        _body.text = n.body;
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

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(appBar: AppBar(title: const Text('Catatan')), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'Catatan Baru' : 'Ubah Catatan'),
        actions: [
          if (widget.noteId != null)
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline, color: JogloColors.danger),
              onPressed: () async {
                await ref.read(simpleStoreProvider).deleteNote(widget.noteId!);
                ref.invalidate(notesProvider);
                if (!context.mounted) return;
                context.pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Judul'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Isi catatan',
              hintText: 'Tulis di sini...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Isi dulu judul atau isinya.')));
                  return;
                }
                await ref.read(simpleStoreProvider).saveNote(
                      id: widget.noteId,
                      title: _title.text,
                      body: _body.text,
                    );
                ref.invalidate(notesProvider);
                if (!context.mounted) return;
                context.pop();
              },
              child: const Text('Simpan Catatan'),
            ),
          ),
        ],
      ),
    );
  }
}
