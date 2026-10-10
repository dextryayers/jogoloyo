// Provider jadwal mingguan. WeekStart dihitung Senin 00.00 UTC.
// Filter: Semua, Saya, Berlangsung, Selesai, Izin.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/app_db.dart';
import '../data/local/les_store.dart';
import '../data/local/session_local_repo.dart';
import '../data/local/seed.dart';

final sessionRepoProvider = Provider((ref) => SessionLocalRepo(ref.watch(appDbProvider)));

final weekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now().toUtc();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime.utc(monday.year, monday.month, monday.day);
});

final scheduleFilterProvider = StateProvider<String>((ref) => 'Semua');

final weekSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final db = ref.watch(appDbProvider);
  final secure = ref.watch(secureStorageProvider);
  // Import di sini agar aman: file ada, import benar.
  await seedIfEmpty(db, secure);
  final week = ref.watch(weekStartProvider);
  final repo = ref.watch(sessionRepoProvider);
  return repo.listWeek(week);
});

final teacherNameProvider = FutureProvider.family<String, String>((ref, teacherId) async {
  final db = ref.watch(appDbProvider);
  final p = await (db.select(db.profiles)..where((t) => t.id.equals(teacherId))).getSingleOrNull();
  return p?.name ?? 'Guru';
});
