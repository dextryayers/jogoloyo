// Tab Jadwal F2.1: minggu Senin sampai Minggu, filter, daftar dari DB lokal.
// Pull to refresh menjalankan resync alarm 14 hari. Tanpa data generik.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/alarm/alarm_service.dart';
import '../../core/alarm/resync.dart';
import '../../core/time/wib.dart';
import '../../data/local/les_store.dart';
import '../../shared/widgets/session_card.dart';
import '../../shared/widgets/states.dart';
import 'alarm_prefs.dart';
import 'schedule_providers.dart';

class ScheduleTab extends ConsumerStatefulWidget {
  const ScheduleTab({super.key});
  @override
  ConsumerState<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<ScheduleTab> with WidgetsBindingObserver {
  final _search = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
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
    final week = ref.watch(weekStartProvider);
    final filter = ref.watch(scheduleFilterProvider);
    final async = ref.watch(weekSessionsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Jadwal Les',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: 'Tambah jadwal',
                  icon: const Icon(Icons.add_circle, color: JogloColors.primary),
                  onPressed: () => context.push('/schedule/new'),
                ),
              ],
            ),
          ),
          _WeekStrip(
            week: week,
            onPrev: () => ref.read(weekStartProvider.notifier).state =
                week.subtract(const Duration(days: 7)),
            onNext: () => ref.read(weekStartProvider.notifier).state =
                week.add(const Duration(days: 7)),
            onToday: () {
              final now = DateTime.now().toUtc();
              final monday = now.subtract(Duration(days: now.weekday - 1));
              ref.read(weekStartProvider.notifier).state =
                  DateTime.utc(monday.year, monday.month, monday.day);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Cari mapel, guru, atau ruang',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          FutureBuilder(
            future: AlarmService().permissions(),
            builder: (c, snap) {
              final exact = snap.data?['exactAlarm'] ?? true;
              if (exact) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: JogloColors.izinBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Expanded(
                          child: Text('Alarm tidak presisi. Aktifkan izin agar H-30 dan H-10 tepat.')),
                      TextButton(
                        onPressed: () => AlarmService().openSettings(),
                        child: const Text('Buka'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['Semua', 'Saya', 'Berlangsung', 'Selesai', 'Izin'].map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: f == filter,
                    onSelected: (_) =>
                        ref.read(scheduleFilterProvider.notifier).state = f,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(weekSessionsProvider);
                final resync = AlarmResync(ref.read(appDbProvider), AlarmService());
                await resync.run();
              },
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: 'Gagal membuka jadwal: $e',
                  onRetry: () => ref.invalidate(weekSessionsProvider),
                ),
                data: (list) {
                  var shown = _applyFilter(list, filter);
                  if (_q.isNotEmpty) {
                    shown = shown.where((e) {
                      final s = '${e.subject} ${e.teacherId} ${e.room}'.toLowerCase();
                      return s.contains(_q);
                    }).toList();
                  }
                  if (shown.isEmpty) {
                    return EmptyState(
                      title: 'Belum ada jadwal',
                      desc:
                          'Belum ada jadwal pada filter ini. Ubah minggu atau hubungi admin jika ini keliru.',
                      actionLabel: 'Ke Minggu Ini',
                      onAction: () {
                        final now = DateTime.now().toUtc();
                        final monday = now.subtract(Duration(days: now.weekday - 1));
                        ref.read(weekStartProvider.notifier).state =
                            DateTime.utc(monday.year, monday.month, monday.day);
                      },
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (c, i) {
                      final s = shown[i];
                      final status = _toStatus(s.status, s.startUtc, s.endUtc);
                      return FutureBuilder(
                        future: AlarmPrefs.load(s.id, 'siswa-sinta'),
                        builder: (cc, snap) {
                          final on = snap.data?.enabled ?? true;
                          return SessionCard(
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
                              status: status,
                              alarmOn: on,
                            ),
                            onTap: () => context.push('/schedule/${s.id}'),
                            onAlarm: () => context.push('/schedule/${s.id}'),
                          );
                        },
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

  List<dynamic> _applyFilter(List<dynamic> list, String f) {
    if (f == 'Semua' || f == 'Saya') return list;
    final now = DateTime.now().toUtc();
    if (f == 'Berlangsung') {
      return list
          .where((e) =>
              e.startUtc.isBefore(now) &&
              e.endUtc.isAfter(now) &&
              e.status != 'cancelled')
          .toList();
    }
    if (f == 'Selesai') {
      return list.where((e) => e.endUtc.isBefore(now) || e.status == 'done').toList();
    }
    return list;
  }

  SessionStatus _toStatus(String raw, DateTime start, DateTime end) {
    if (raw == 'cancelled') return SessionStatus.cancelled;
    if (raw == 'done') return SessionStatus.done;
    final now = DateTime.now().toUtc();
    if (start.isBefore(now) && end.isAfter(now)) return SessionStatus.ongoing;
    if (end.isBefore(now)) return SessionStatus.done;
    return SessionStatus.scheduled;
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime week;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  const _WeekStrip(
      {required this.week, required this.onPrev, required this.onNext, required this.onToday});

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => week.add(Duration(days: i)));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(
                  '${Wib.dmy(days.first)} - ${Wib.dmy(days.last)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: days.map((d) {
              final isToday = DateTime.now().toUtc().day == d.day &&
                  DateTime.now().toUtc().month == d.month;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? JogloColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: JogloColors.line),
                ),
                child: Column(
                  children: [
                    Text(['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'][d.weekday - 1],
                        style: TextStyle(
                            color: isToday ? Colors.white : JogloColors.muted,
                            fontSize: 12)),
                    Text('${d.day}',
                        style: TextStyle(
                            color: isToday ? Colors.white : JogloColors.ink,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        TextButton(onPressed: onToday, child: const Text('Kembali ke minggu ini')),
      ],
    );
  }
}
