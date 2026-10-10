// Tab Pengingat: daftar simpel, toggle aktif, tambah, ubah, hapus, tes.
// Setiap simpan langsung dijadwalkan ke alarm exact. Bunyi plus getar otomatis.
// Banner jujur bila izin presisi mati. Resync tiap resume.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../data/local/simple_store.dart';
import '../../shared/widgets/states.dart';
import '../../features/schedule/alarm_prefs.dart';

class ReminderTab extends ConsumerStatefulWidget {
  const ReminderTab({super.key});
  @override
  ConsumerState<ReminderTab> createState() => _State();
}

class _State extends ConsumerState<ReminderTab> with WidgetsBindingObserver {
  bool _exact = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    Future.microtask(() async {
      await ref.read(simpleStoreProvider).rescheduleAll();
      ref.invalidate(remindersProvider);
    });
  }

  Future<void> _check() async {
    final perm = await AlarmService().permissions();
    if (mounted) setState(() => _exact = perm['exactAlarm'] ?? true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(simpleStoreProvider).rescheduleAll();
      ref.invalidate(remindersProvider);
      _check();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (!_exact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: JogloColors.izinBg, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text(
                            'Izin presisi mati. Bunyi bisa telat. Nyalakan agar tepat menit.')),
                    TextButton(
                      onPressed: () async {
                        await AlarmService().openSettings();
                        _check();
                      },
                      child: const Text('Buka'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(remindersProvider);
                await ref.read(simpleStoreProvider).rescheduleAll();
                await _check();
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
                      icon: Icons.add_alarm_outlined,
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
                              '${wibDay(r.whenUtc)} ${wibHm(r.whenUtc)} WIB . ${r.daily ? 'Tiap hari' : 'Sekali'} . ${_soundName(r.sound)} . ${r.level}%${r.vibrate ? '' : ' . Tanpa getar'}'),
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
