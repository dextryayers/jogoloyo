// Tab Pengingat: daftar simpel, toggle aktif, tambah, ubah, hapus, tes.
// Setiap simpan langsung dijadwalkan ke alarm exact. Bunyi plus getar otomatis.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/local/simple_store.dart';
import '../../shared/widgets/states.dart';
import '../../features/schedule/alarm_prefs.dart';

class ReminderTab extends ConsumerWidget {
  const ReminderTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(remindersProvider);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Pengingat',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: 'Tambah pengingat',
                  icon: const Icon(Icons.add_circle, color: JogloColors.primary, size: 32),
                  onPressed: () => context.push('/reminder/new'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(remindersProvider);
                await ref.read(simpleStoreProvider).rescheduleAll();
              },
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                    message: 'Gagal: $e', onRetry: () => ref.invalidate(remindersProvider)),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      title: 'Belum ada pengingat',
                      desc: 'Buat yang pertama. Atur jam, pilih suara, tes bunyi.',
                      actionLabel: 'Tambah',
                      onAction: () => context.push('/reminder/new'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (c, i) {
                      final r = list[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            r.enabled ? Icons.alarm_on : Icons.alarm_off,
                            color: r.enabled ? JogloColors.primary : JogloColors.muted,
                          ),
                          title: Text(r.title.isEmpty ? 'Pengingat' : r.title),
                          subtitle: Text(
                              '${wibDay(r.whenUtc)} ${wibHm(r.whenUtc)} WIB . ${r.daily ? 'Tiap hari' : 'Sekali'} . ${_soundName(r.sound)}'),
                          trailing: Switch(
                            value: r.enabled,
                            onChanged: (v) async {
                              await ref.read(simpleStoreProvider).upsertReminder(Reminder(
                                  id: r.id,
                                  title: r.title,
                                  whenUtc: r.whenUtc,
                                  sound: r.sound,
                                  level: r.level,
                                  vibrate: r.vibrate,
                                  enabled: v,
                                  daily: r.daily));
                              await ref.read(simpleStoreProvider).rescheduleAll();
                              ref.invalidate(remindersProvider);
                            },
                          ),
                          onTap: () => context.push('/reminder/${r.id}'),
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

  String _soundName(String id) {
    for (final s in AlarmSound.options) {
      if (s.id == id) return s.label;
    }
    return 'Suara 1';
  }
}
