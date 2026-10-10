// Tab Catatan: notepad rapi. Cari, geser hapus plus urungkan, FAB tulis.
// Strip warna lembut per catatan agar mudah bedakan sekilas.
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
              child: async.when(
                loading: () => const Text('Catatan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                error: (_, _) => const Text('Catatan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                data: (list) => Text('Catatan . ${list.length}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                    message: 'Gagal: $e', onRetry: () => ref.invalidate(notesProvider)),
                data: (list) {
                  final shown = _q.isEmpty
                      ? list
                      : list.where((e) => '${e.title} ${e.body}'.toLowerCase().contains(_q)).toList();
                  if (shown.isEmpty) {
                    return EmptyState(
                      title: _q.isEmpty ? 'Belum ada catatan' : 'Tidak ketemu',
                      desc: _q.isEmpty
                          ? 'Tulis hal penting agar tidak lupa. Tersimpan di HP ini.'
                          : 'Coba kata kunci lain.',
                      actionLabel: 'Tulis',
                      icon: Icons.edit_outlined,
                      onAction: () => context.push('/note/new'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (c, i) {
                      final n = shown[i];
                      final words = n.body.trim().isEmpty
                          ? 0
                          : n.body.trim().split(RegExp(r'\s+')).length;
                      return Dismissible(
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
                                  content: Text('"${n.title.isEmpty ? '(Tanpa judul)' : n.title}" dihapus?'),
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
                          strip: _strips[i % _strips.length],
                          onTap: () => context.push('/note/${n.id}'),
                        ),
                      );
                    },
                  );
                },
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
    return '${w.day} ${months[w.month]} ${w.year} . ${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  }
}

class _NoteCard extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final int words;
  final Color strip;
  final VoidCallback onTap;
  const _NoteCard({
    required this.title,
    required this.body,
    required this.date,
    required this.words,
    required this.strip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                    Text(title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(body, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: JogloColors.muted, fontSize: 13)),
                    ],
                    const SizedBox(height: 6),
                    Text('$date . $words kata',
                        style: const TextStyle(fontSize: 11, color: JogloColors.muted)),
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
