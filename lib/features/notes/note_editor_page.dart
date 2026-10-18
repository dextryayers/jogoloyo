// Editor catatan: judul besar, isi lega, hitung kata dan karakter live,
// status autosave, simpan besar di bawah, ekspor dan hapus lewat menu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/local/simple_store.dart';
import 'note_export_sheet.dart';

const _bulan = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

class NoteEditorPage extends ConsumerStatefulWidget {
  final String? noteId;
  const NoteEditorPage({super.key, this.noteId});
  @override
  ConsumerState<NoteEditorPage> createState() => _State();
}

class _State extends ConsumerState<NoteEditorPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _bodyFocus = FocusNode();
  final _titleFocus = FocusNode();

  bool _ready = false;
  bool _saved = false;
  String? _id;
  DateTime? _updated;
  bool _dirty = false;
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    _id = widget.noteId;
    _body.addListener(_onChange);
    _title.addListener(_onChange);
    _load();
  }

  void _onChange() {
    final w = _words(_body.text);
    if (w != _wordsCount || _dirty != _body.text.trim().isNotEmpty) {
      setState(() {
        _wordsCount = w;
        _dirty = _body.text.trim().isNotEmpty || _title.text.trim().isNotEmpty;
      });
    }
  }

  int _wordsCount = 0;

  int _words(String body) {
    final t = body.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
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
        _wordsCount = _words(n.body);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan tidak ditemukan. Mungkin sudah dihapus.')),
        );
        context.pop();
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _ready = true;
      _dirty = _body.text.trim().isNotEmpty || _title.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _title.removeListener(_onChange);
    _body.removeListener(_onChange);
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  // Autosave: keluar tanpa tekan Simpan tetap aman. Tulis ulang id yang sama
  // supaya tidak jadi catatan ganda.
  Future<String?> _persist() async {
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) return null;
    final nid = await ref.read(simpleStoreProvider).saveNote(
          id: _id,
          title: _title.text,
          body: _body.text,
        );
    _id = nid;
    _updated = DateTime.now().toUtc();
    _dirty = false;
    ref.invalidate(notesProvider);
    return nid;
  }

  Future<void> _autoSave() async {
    if (_saved) return;
    if (!_dirty) return;
    await _persist();
  }

  Future<void> _saveAndClose() async {
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi dulu judul atau isinya.')),
      );
      return;
    }
    await _persist();
    if (!mounted) return;
    _saved = true;
    setState(() => _justSaved = true);
    ref.invalidate(notesProvider);
    await ref.read(notesProvider.future);
    if (!mounted) return;
    context.go('/notes');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan tersimpan di HP ini.')),
    );
  }

  Future<void> _delete() async {
    final target = _id;
    if (target == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Hapus catatan'),
        content: const Text('Catatan ini dihapus dari HP ini. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JogloColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    await ref.read(simpleStoreProvider).deleteNote(target);
    _saved = true;
    ref.invalidate(notesProvider);
    if (!mounted) return;
    context.go('/notes');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catatan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chars = _body.text.length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _autoSave();
      },
      child: Scaffold(
        backgroundColor: JogloColors.paper,
        appBar: AppBar(
          backgroundColor: JogloColors.paper,
          title: Text(widget.noteId == null ? 'Catatan Baru' : 'Ubah Catatan'),
          actions: [
            IconButton(
              tooltip: 'Ekspor PNG, JPG, atau PDF',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: () => _openExport(),
            ),
            if (_id != null)
              IconButton(
                tooltip: 'Hapus catatan',
                icon: const Icon(Icons.delete_outline, color: JogloColors.danger),
                onPressed: _delete,
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  TextField(
                    controller: _title,
                    focusNode: _titleFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _bodyFocus.requestFocus(),
                    maxLines: null,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Judul',
                      hintStyle: TextStyle(
                        color: JogloColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_updated != null)
                        Flexible(
                          child: Text(
                            _date(_updated!),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: JogloColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '$_wordsCount kata . $chars karakter',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: JogloColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _body,
                    focusNode: _bodyFocus,
                    autofocus: widget.noteId == null,
                    maxLines: null,
                    minLines: 12,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 15.5, height: 1.65),
                    decoration: const InputDecoration(
                      hintText: 'Tulis di sini...',
                      hintStyle: TextStyle(color: JogloColors.muted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            _BottomBar(
              dirty: _dirty,
              justSaved: _justSaved,
              onSave: _saveAndClose,
              viewInsets: MediaQuery.of(context).viewInsets.bottom,
            ),
          ],
        ),
      ),
    );
  }

  void _openExport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: JogloColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NoteExportSheet(
        title: _title.text,
        body: _body.text,
        date: _updated == null ? 'Baru' : _date(_updated!),
      ),
    );
  }

  String _date(DateTime utc) {
    final w = utc.toUtc().add(const Duration(hours: 7));
    final hh = w.hour.toString().padLeft(2, '0');
    final mm = w.minute.toString().padLeft(2, '0');
    return 'Terakhir ${w.day} ${_bulan[w.month]} ${w.year} $hh:$mm WIB';
  }
}

class _BottomBar extends StatelessWidget {
  final bool dirty;
  final bool justSaved;
  final Future<void> Function() onSave;
  final double viewInsets;

  const _BottomBar({
    required this.dirty,
    required this.justSaved,
    required this.onSave,
    required this.viewInsets,
  });

  @override
  Widget build(BuildContext context) {
    final label = justSaved
        ? 'Tersimpan'
        : dirty
            ? 'Belum tersimpan'
            : 'Tersimpan otomatis';
    final color = dirty && !justSaved ? JogloColors.warning : JogloColors.success;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, viewInsets + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: JogloColors.line)),
      ),
      child: Row(
        children: [
          Icon(
            justSaved ? Icons.check_circle_outline : Icons.cloud_done_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}