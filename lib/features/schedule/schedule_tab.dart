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

class _ScheduleTabState extends ConsumerState<ScheduleTab> {
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
  