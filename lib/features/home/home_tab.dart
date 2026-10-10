// Dashboard simpel: sapaan, pengingat hari ini, aksi cepat, ringkasan catatan.
// Reschedule alarm tiap dibuka dan tiap resume agar harian tepat waktu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/log/app_log.dart';
import '../../data/local/simple_store.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/states.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});
  @override
  ConsumerState<HomeTab> createState() => _State();
}

class _State extends ConsumerState<HomeTab> with WidgetsBindingObserver {
  String _name = 'Guru';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      final p = await SharedPreferences.getInstance();
      if (mounted) setState(() => _name = p.getString('user_name') ?? 'Guru');
      final r = await ref.read(simpleStoreProvider).rescheduleAll();
      AppLog.record('resync', 'scheduled=${r.scheduled}');
      ref.invalidate(remindersProvider);
    });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(remindersProvider);
    final notes = ref.watch(notesProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(simpleStoreProvider).rescheduleAll();
          ref.invalidate(remindersProvider);
          ref.invalidate(notesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Row(
              children: [
                AppLogo(size: 40, radius: 12),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Les Jogoloyo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('Pengingat berbunyi plus catatan.',
                        style: TextStyle(fontSize: 12, color: JogloColors.muted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_greeting(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Hari ini',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: JogloColors.muted)),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Card(
                  child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))),
              error: (e, _) => ErrorView(
                  message: 'Gagal: $e', onRetry: () => ref.invalidate(remindersProvider)),
              data: (list) {
                final today = _today(list);
                if (today.isEmpty) {
                  return EmptyState(
                    title: 'Hari ini kosong',
                    desc: 'Belum ada pengingat hari ini. Tambah satu agar berbunyi tepat waktu.',
                    actionLabel: 'Tambah',
                    onAction: () => context.push('/reminder/new'),
                  );
                }
                return Column(
                  children: [
                    for (final r in today)
                      Card(
                        child: ListTile(
                          leading: Icon(r.enabled ? Icons.alarm_on : Icons.alarm_off,
                              color: r.enabled ? JogloColors.primary : JogloColors.muted),
                          title: Text(r.title.isEmpty ? 'Pengingat' : r.title),
                          subtitle: Text('${wibHm(r.whenUtc)} WIB . ${r.daily ? 'Tiap hari' : 'Sekali'}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/reminder/${r.id}'),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/reminder/new'),
                    icon: const Icon(Icons.add_alarm_outlined),
                    label: const Text('Pengingat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/notes'),
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('Catatan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            notes.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) => Card(
                child: ListTile(
                  leading: const Icon(Icons.note_outlined, color: JogloColors.primary),
                  title: Text('${list.length} catatan'),
                  subtitle: const Text('Ketuk untuk buka notepad.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/notes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Reminder> _today(List<Reminder> all) {
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    return all.where((r) {
      if (!r.enabled) return false;
      if (r.daily) return true;
      final w = r.whenUtc.toUtc().add(const Duration(hours: 7));
      return w.year == nowWib.year && w.month == nowWib.month && w.day == nowWib.day;
    }).toList()
      ..sort((a, b) => a.whenUtc.compareTo(b.whenUtc));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi, $_name.';
    if (h < 15) return 'Selamat siang, $_name.';
    if (h < 19) return 'Selamat sore, $_name.';
    return 'Selamat malam, $_name.';
  }
}
