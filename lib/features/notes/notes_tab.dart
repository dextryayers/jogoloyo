// Tab Catatan: notepad rapi. Grup Disematkan, Hari ini, Kemarin, Sebelumnya.
// Cari, sematkan via tahan, geser hapus plus urungkan, urut baru atau lama, FAB tulis.
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

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});
  @override
  ConsumerState<NotesTab> createState() => _State();
}

class _State extends ConsumerState<NotesTab> {
  String _q = '';
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notesProvider);
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/note/new'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Tulis'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: async.when(
                      loading: () => const Text('Catatan',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      error: (_, _) => const Text('Catatan',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      data: (list) => Text('Catatan . ${list.length}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  IconButton(
                    tooltip: _newestFirst ? 'Terbaru dulu' : 'Terlama dulu',
                    icon: Icon(_newestFirst ? Icons.arrow_downward : Icons.arrow_upward),
                    onPressed: () => setState(() => _newestFirst = !_newestFirst),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari judul atau isi',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                ),
                onChanged: (v) => setState(() => _q = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notesProvider);
                  await ref.read(notesProvider.future);
                },
                child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                    message: 'Gagal: $e', onRetry: () => ref.invalidate(notesProvider)),
                data: (list) {
                  var shown = _q.isEmpty
                      ? list
                      : list
                          .where((e) => '${e.title} ${e.body}'.toLowerCase().contains(_q))
                          .toList();
                  shown = [...shown];
                  shown.sort((a, b) {
                    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
                    return _newestFirst
                        ? b.updatedAt.compareTo(a.updatedAt)
                        : a.updatedAt.compareTo(b.updatedAt);
                  });
                  if (shown.isEmpty) {
                    return EmptyState(
                      title: _q.isEmpty ? 'Belum ada catatan' : 'Tidak ketemu',
                      desc: _q.isEmpty
                          ? 'Tulis hal penting agar tidak lupa. Ketuk kartu untuk buka dan ubah lagi.'
                          : 'Coba kata kunci lain.',
                      actionLabel: 'Tulis',
                      icon: Icons.edit_outlined,
                      onAction: () => context.push('/note/new'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: shown.length,
                    itemBuilder: (c, i) {
                      final n = shown[i];
                      final header = _headerFor(shown, i);
                      final words = n.body.trim().isEmpty
                          ? 0
                          : n.body.trim().split(RegExp(r'\s+')).length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (header != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(header,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: JogloColors.muted)),
                            ),
                          Dismissible(
                            key: ValueKey(n.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: JogloColors.danger,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (d) => AlertDialog(
                                      title: const Text('Hapus catatan'),
                                      content: Text(
                                          '"${n.title.isEmpty ? '(Tanpa judul)' : n.title}" dihapus?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(d, false),
                                            child: const Text('Batal')),
                                        ElevatedButton(
                                            onPressed: () => Navigator.pop(d, true),
                                            child: const Text('Hapus')),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (_) async {
                              await ref.read(simpleStoreProvider).deleteNote(n.id);
                              ref.invalidate(notesProvider);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Catatan dihapus.'),
                                action: SnackBarAction(
                                  label: 'Urungkan',
                                  onPressed: () async {
                                    await ref.read(simpleStoreProvider).saveNote(
                                          id: n.id,
                                          title: n.title,
                                          body: n.body,
                                        );
                                    ref.invalidate(notesProvider);
                                  },
                                ),
                              ));
                            },
                            child: _NoteCard(
                              title: n.title.isEmpty ? '(Tanpa judul)' : n.title,
                              body: n.body,
                              date: _date(n.updatedAt),
                              words: words,
                              pinned: n.pinned,
                              strip: _strips[i % _strips.length],
                              onTap: () => context.push('/note/${n.id}'),
                              onPin: () async {
                                await ref.read(simpleStoreProvider).togglePin(n.id);
                                ref.invalidate(notesProvider);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  );
                },
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _headerFor(List<Note> list, int i) {
    String group(Note n) {
      if (n.pinned) return 'Disematkan';
      final w = n.updatedAt.toUtc().add(const Duration(hours: 7));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(w.year, w.month, w.day);
      final diff = today.difference(day).inDays;
      if (diff <= 0) return 'Hari ini';
      if (diff == 1) return 'Kemarin';
      return 'Sebelumnya';
    }

    final g = group(list[i]);
    if (i == 0) return g;
    if (group(list[i - 1]) == g) return null;
    return g;
  }

  String _date(DateTime utc) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final w = utc.toUtc().add(const Duration(hours: 7));
    return '${w.day} ${months[w.month]} ${w.year} . ${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onPin,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: strip,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (pinned)
                          const Icon(Icons.push_pin, size: 16, color: JogloColors.warning),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: JogloColors.muted, fontSize: 13)),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('$date . $words kata',
                              style: const TextStyle(fontSize: 11, color: JogloColors.muted)),
                        ),
                        InkWell(
                          onTap: onPin,
                          child: Text(pinned ? 'Lepas' : 'Semat',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: JogloColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: JogloColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
