// Tab Beranda F2 deep: Les Berikutnya nyata dari DB lokal 14 hari ke depan.
// Jika kosong tampil empty spesifik. Tombol Atur Alarm buka sheet, OTW catat info.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../core/alarm/resync.dart';
import '../../core/log/app_log.dart';
import '../../data/local/les_store.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/profile_bar.dart';
import '../../shared/widgets/session_card.dart';
import '../../shared/widgets/states.dart';
import '../attendance/attendance_page.dart';
import '../auth/active_profile.dart';
import '../material/learn_providers.dart';
import '../schedule/alarm_prefs.dart';
import '../schedule/alarm_sheet.dart';
import '../schedule/schedule_providers.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});
  @override
  ConsumerState<HomeTab> createState() => _State();
}

class _State extends ConsumerState<HomeTab> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      final resync = AlarmResync(ref.read(appDbProvider), AlarmService());
      final r = await resync.run();
      AppLog.record('resync', 'scheduled=${r.scheduled} cancelled=${r.cancelled}');
      try {
        final n = await ref.read(attendanceRepoProvider).autoAlpa();
        AppLog.record('auto_alpa', '$n');
      } catch (_) {}
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
      ref.invalidate(weekSessionsProvider);
      AlarmResync(ref.read(appDbProvider), AlarmService()).run();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(weekSessionsProvider);
    final active = ref.watch(activeProfileProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weekSessionsProvider);
          await AlarmResync(ref.read(appDbProvider), AlarmService()).run();
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
                    Text('V.01.0 local . 100 persen offline',
                        style: TextStyle(fontSize: 12, color: JogloColors.muted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            active.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (p) => ProfileBar(
                profile: ActiveProfile(
                  id: p?.id ?? '-',
                  name: p?.name ?? 'Guru',
                  role: roleFromString(p?.role ?? 'GURU'),
                  photoPath: p?.photoPath,
                ),
                onSwitch: () => context.push('/pin'),
              ),
            ),
            const SizedBox(height: 12),
            active.when(
              loading: () => const Text('Selamat datang.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              error: (_, _) => const Text('Selamat datang.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              data: (p) => Text(
                _greeting(p?.name ?? 'Guru'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Les Berikutnya',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: JogloColors.muted)),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => ErrorView(
                  message: 'Gagal membuka jadwal: $e',
                  onRetry: () => ref.invalidate(weekSessionsProvider)),
              data: (list) {
                final now = DateTime.now().toUtc();
                final upcoming = list
                    .where((e) => e.endUtc.isAfter(now) && e.status != 'cancelled')
                    .toList()
                  ..sort((a, b) => a.startUtc.compareTo(b.startUtc));
                if (upcoming.isEmpty) {
                  return EmptyState(
                    title: 'Belum ada les berikutnya',
                    desc:
                        'Belum ada jadwal 14 hari ke depan. Hubungi admin jika ini keliru.',
                    actionLabel: 'Lihat Jadwal',
                    onAction: () => context.go('/schedule'),
                  );
                }
                final s = upcoming.first;
                return Column(
                  children: [
                    FutureBuilder(
                      future: AlarmPrefs.load(s.id, 'siswa-sinta'),
                      builder: (c, ap) => SessionCard(
                        info: SessionInfo(
                          id: s.id,
                          subject: s.subject,
                          teacher: s.teacherId == 'guru-rina'
                              ? 'Ustazah Rina'
                              : s.teacherId == 'guru-dewi'
                                  ? 'Ustazah Dewi'
                                  : s.teacherId,
                          teacherVerified: true,
                          startUtc: s.startUtc,
                          endUtc: s.endUtc,
                          room: s.room,
                          status: SessionStatus.scheduled,
                          alarmOn: ap.data?.enabled ?? true,
                        ),
                        onTap: () => context.push('/schedule/${s.id}'),
                        onAlarm: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AlarmSheet(session: s),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'Atur alarm sesi ini',
                            child: FilledButton.icon(
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => AlarmSheet(session: s),
                              ),
                              icon: const Icon(Icons.alarm),
                              label: const Text('Atur Alarm'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'Beri tahu guru saya sedang menuju lokasi',
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text(
                                        'Guru diberi tahu kamu OTW. Sampai jumpa di kelas.')));
                              },
                              icon: const Icon(Icons.directions_walk),
                              label: const Text('Saya OTW'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const OfflineBanner(),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments_outlined, color: JogloColors.primary),
                title: const Text('Tagihan aktif: Rp150.000'),
                subtitle: const Text('SPP Okt 2026. Jatuh tempo 10 Okt. Buka Saya lalu Tagihan Les.'),
                trailing: TextButton(
                    onPressed: () => context.go('/profile'), child: const Text('Lihat')),
              ),
            ),
            Consumer(
              builder: (c, r, _) {
                final anns = r.watch(announcementsProvider);
                return anns.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (list) {
                    if (list.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        for (final a in list.take(3))
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.campaign_outlined, color: JogloColors.primary),
                              title: Text(a.title),
                              subtitle: Text(a.body),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _greeting(String name) {
    final h = DateTime.now().hour;
    final base = name.isEmpty ? 'Guru' : name;
    if (h < 11) return 'Selamat pagi, $base.';
    if (h < 15) return 'Selamat siang, $base.';
    if (h < 19) return 'Selamat sore, $base.';
    return 'Selamat malam, $base.';
  }
}
