// Tab Catatan: daftar notepad modern. Cari, saring, sematkan, hapus geser, urutkan.
// Catatan tersimpan lokal di HP. Buka kartu untuk ubah, ekspor, atau hapus.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/local/simple_store.dart';
import '../../shared/widgets/states.dart';

const _strips = [
  Color(0xFF1B5E20),
  Color(0xFFEF6C00),
  Color(0xFF37474F),
  Color(0xFF6D4C41),
];

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

enum _Filter { semua, disematkan, hariIni }

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});
  @override
  ConsumerState<NotesTab> createState() => _State();
}

class _State extends ConsumerState<NotesTab> {
  final _search = TextEditingController();
  String _q = '';
  bool _newestFirst = true;
  _Filter _filter = _Filter.semua;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openEditor(String? id) async {
    await context.push(id == null ? '/note/new' : '/note/$id');
    if (!mounted) return;
    ref.invalidate(notesProvider);
  }

  Future<void> _delete(Note n) async {
    await ref.read(simpleStoreProvider).deleteNote(n.id);
    ref.invalidate(notesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Catatan "${_label(n.title)}" dihapus.'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () async {
            await ref
                .read(simpleStoreProvider)
                .saveNote(id: n.id, title: n.title, body: n.body);
            ref.invalidate(notesProvider);
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Note n) async {
    return await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Hapus catatan'),
            content: Text('"${_label(n.title)}" dihapus dari HP ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Batal'),
              ),
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
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notesProvider);
    final count = async.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(null),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Tulis'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(count: count, newestFirst: _newestFirst, onSort: _toggleSort),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari judul atau isi catatan',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Bersihkan pencarian',
                        onPressed: () {
                          _search.clear();
                          setState(() => _q = '');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: JogloColors.paper,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _FilterBar(
            active: _filter,
            onChanged: (v) => setState(() => _filter = v),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notesProvider);
                await ref.read(notesProvider.future);
              },
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => ErrorView(
                  message: 'Gagal memuat catatan: $e',
                  onRetry: () => ref.invalidate(notesProvider),
                ),
                data: (list) {
                  final shown = _apply(list);
                  if (shown.isEmpty) {
                    return LayoutBuilder(
                      builder: (context, c) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: c.maxHeight,
                          child: _emptyState(),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = shown[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          decoration: BoxDecoration(
                            color: JogloColors.danger,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.delete_outline, color: Colors.white),
                            ],
                          ),
                        ),
                        confirmDismiss: (_) => _confirmDelete(n),
                        onDismissed: (_) => _delete(n),
                        child: _NoteCard(
                          title: _label(n.title),
                          body: n.body,
                          date: _date(n.updatedAt),
                          words: _words(n.body),
                          pinned: n.pinned,
                          strip: _strips[i % _strips.length],
                          onTap: () => _openEditor(n.id),
                          onPin: () async {
                            await ref
                                .read(simpleStoreProvider)
                                .togglePin(n.id);
                            ref.invalidate(notesProvider);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSort() {
    setState(() => _newestFirst = !_newestFirst);
    ref.invalidate(notesProvider);
  }

  List<Note> _apply(List<Note> list) {
    var out = list.where((n) {
      if (_q.isEmpty) return true;
      return '${n.title} ${n.body}'.toLowerCase().contains(_q);
    }).toList();

    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    switch (_filter) {
      case _Filter.semua:
        break;
      case _Filter.disematkan:
        out = out.where((n) => n.pinned).toList();
        break;
      case _Filter.hariIni:
        out = out.where((n) {
          if (n.pinned) return true;
          final w = n.updatedAt.toUtc().add(const Duration(hours: 7));
          return w.year == nowWib.year &&
              w.month == nowWib.month &&
              w.day == nowWib.day;
        }).toList();
        break;
    }

    out.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return _newestFirst
          ? b.updatedAt.compareTo(a.updatedAt)
          : a.updatedAt.compareTo(b.updatedAt);
    });
    return out;
  }

  Widget _emptyState() {
    final searching = _q.isNotEmpty;
    return switch ((searching, _filter)) {
      (true, _) => EmptyState(
          title: 'Tidak ketemu',
          desc: 'Coba kata kunci lain.',
          icon: Icons.search_off,
          actionLabel: 'Bersihkan',
          onAction: () {
            _search.clear();
            setState(() {
              _q = '';
              _filter = _Filter.semua;
            });
          },
        ),
      (false, _Filter.disematkan) => const EmptyState(
          title: 'Belum ada yang disematkan',
          desc: 'Tekan tombol Semat pada catatan agar mudah dicari.',
          icon: Icons.push_pin_outlined,
        ),
      (false, _) => EmptyState(
          title: 'Belum ada catatan',
          desc: 'Tulis hal penting agar tidak lupa. Tersimpan lokal di HP ini.',
          actionLabel: 'Tulis',
          icon: Icons.edit_outlined,
          onAction: () => _openEditor(null),
        ),
    };
  }

  String _label(String t) => t.trim().isEmpty ? '(Tanpa judul)' : t.trim();

  int _words(String body) {
    final t = body.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  String _date(DateTime utc) {
    final w = utc.toUtc().add(const Duration(hours: 7));
    final hh = w.hour.toString().padLeft(2, '0');
    final mm = w.minute.toString().padLeft(2, '0');
    return '${w.day} ${_bulan[w.month]} ${w.year} . $hh:$mm';
  }
}

class _Header extends StatelessWidget {
  final int count;
  final bool newestFirst;
  final VoidCallback onSort;

  const _Header({
    required this.count,
    required this.newestFirst,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0
                      ? 'Belum ada catatan tersimpan'
                      : '$count catatan tersimpan lokal di HP',
                  style: const TextStyle(fontSize: 12, color: JogloColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: newestFirst ? 'Urutkan terbaru dulu' : 'Urutkan terlama dulu',
            onPressed: onSort,
            icon: Icon(
              newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _Filter active;
  final ValueChanged<_Filter> onChanged;

  const _FilterBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _chip('Semua', _Filter.semua),
          const SizedBox(width: 8),
          _chip('Disematkan', _Filter.disematkan),
          const SizedBox(width: 8),
          _chip('Hari ini', _Filter.hariIni),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter value) {
    return ChoiceChip(
      label: Text(label),
      selected: active == value,
      onSelected: (_) => onChanged(value),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final int words;
  final bool pinned;
  final Color strip;
  final VoidCallback onTap;
  final VoidCallback onPin;

  const _NoteCard({
    required this.title,
    required this.body,
    required this.date,
    required this.words,
    required this.pinned,
    required this.strip,
    required this.onTap,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final hasBody = body.trim().isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      elevation: pinned ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pinned ? strip : JogloColors.line,
          width: pinned ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onPin,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: strip, width: 5)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pinned)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 2),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: JogloColors.warning,
                      ),
                    ),
                ],
              ),
              if (hasBody) ...[
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: JogloColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 13,
                    color: JogloColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$date . $words kata',
                      style: const TextStyle(
                        fontSize: 11,
                        color: JogloColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onPin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        pinned ? 'Lepas' : 'Semat',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: JogloColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}