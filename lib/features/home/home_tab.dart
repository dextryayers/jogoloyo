// Dashboard simpel: sapaan, pengingat hari ini, aksi cepat, ringkasan catatan.
// Reschedule alarm tiap dibuka dan tiap resume agar harian tepat waktu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
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
            const Text('Jalan Pintas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: JogloColors.muted)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                _Shortcut(
                  icon: Icons.add_alarm_outlined,
                  label: 'Pengingat Baru',
                  onTap: () => context.push('/reminder/new'),
                ),
                _Shortcut(
                  icon: Icons.alarm_outlined,
                  label: 'Daftar Pengingat',
                  onTap: () => context.push('/reminders'),
                ),
                _Shortcut(
                  icon: Icons.note_add_outlined,
                  label: 'Catatan Baru',
                  onTap: () => context.push('/note/new'),
                ),
                _Shortcut(
                  icon: Icons.volume_up_outlined,
                  label: 'Tes Bunyi',
                  onTap: () async {
                    final p = await SharedPreferences.getInstance();
                    await AlarmService().test('urgent',
                        sound: p.getString('default_sound') ?? 'suara1',
                        loud: p.getBool('default_loud') ?? true);
                  },
                ),
                _Shortcut(
                  icon: Icons.notifications_outlined,
                  label: 'Waktu Notifikasi',
                  onTap: () => context.push('/notif-setup'),
                ),
                _Shortcut(
                  icon: Icons.person_outline,
                  label: 'Profil Saya',
                  onTap: () => context.go('/profile'),
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

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Shortcut({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: JogloColors.primary, size: 28),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
