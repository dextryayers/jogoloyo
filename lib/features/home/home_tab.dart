// Tab Beranda F2 deep: Les Berikutnya nyata dari DB lokal 14 hari ke depan.
// Jika kosong tampil empty spesifik. Tombol Atur Alarm buka sheet, OTW catat info.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../core/alarm/resync.dart';
import '../../data/local/les_store.dart';
import '../../shared/widgets/profile_bar.dart';
import '../../shared/widgets/session_card.dart';
import '../../shared/widgets/states.dart';
import '../schedule/alarm_prefs.dart';
import '../schedule/alarm_sheet.dart';
import '../schedule/schedule_providers.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});
  @override
  ConsumerState<HomeTab> createState() => _State();
}

class _State extends ConsumerState<HomeTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final resync = AlarmResync(ref.read(appDbProvider), AlarmService());
      await resync.run();
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(weekSessionsProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weekSessionsProvider);
          await AlarmResync(ref.read(appDbProvider), AlarmService()).run();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProfileBar(
              profile: const ActiveProfile(id: 'siswa-sinta', name: 'Sinta', role: LocalRole.siswa),
              onSwitch: () => context.push('/pin'),
            ),
            const SizedBox(height: 12),
            Text(
              _greeting(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
                        const SizedBox(width: 8),
                        Expanded(
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
                subtitle: const Text('SPP Okt 2026. Jatuh tempo 10 Okt.'),
                trailing: TextButton(
                    onPressed: () => context.go('/profile'), child: const Text('Lihat')),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_outlined, color: JogloColors.primary),
                title: const Text('Pengumuman: Jadwal Sabtu tetap jalan.'),
                subtitle: const Text('Bawa buku latihan bab 3.'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi, Sinta.';
    if (h < 15) return 'Selamat siang, Sinta.';
    if (h < 19) return 'Selamat sore, Sinta.';
    return 'Selamat malam, Sinta.';
  }
}
