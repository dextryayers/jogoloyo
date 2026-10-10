// Tab Catatan: notepad simpel. Cari, tambah, ubah, hapus. Autosave saat simpan.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/local/simple_store.dart';
import '../../shared/widgets/states.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Catatan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: 'Tambah catatan',
                  icon: const Icon(Icons.add_circle, color: JogloColors.primary, size: 32),
                  onPressed: () => context.push('/note/new'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Cari catatan', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: 'Gagal: $e', onRetry: () => ref.invalidate(notesProvider)),
              data: (list) {
                final shown = _q.isEmpty
                    ? list
                    : list.where((e) => '${e.title} ${e.body}'.toLowerCase().contains(_q)).toList();
                if (shown.isEmpty) {
                  return EmptyState(
                    title: 'Belum ada catatan',
                    desc: 'Tulis hal penting agar tidak lupa.',
                    actionLabel: 'Tulis',
                    onAction: () => context.push('/note/new'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (c, i) {
                    final n = shown[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.note_outlined, color: JogloColors.primary),
                        title: Text(n.title.isEmpty ? '(Tanpa judul)' : n.title),
                        subtitle: Text(
                          n.body.length > 80 ? '${n.body.substring(0, 80)}...' : n.body,
                          maxLines: 2,
                        ),
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
    );
  }
}
