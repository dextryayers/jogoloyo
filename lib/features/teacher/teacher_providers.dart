// Provider guru: daftar plus pending plus detail verifikasi.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';
import 'teacher_repo.dart';

final teacherRepoProvider = Provider((ref) => TeacherRepo(ref.watch(appDbProvider)));

final guruListProvider = FutureProvider<List<Profile>>((ref) async {
  final db = ref.watch(appDbProvider);
  return (db.select(db.profiles)..where((t) => t.role.equals('GURU'))).get();
});

final pendingVerifProvider = FutureProvider<List<TeacherVerif>>((ref) async {
  return ref.watch(teacherRepoProvider).pending();
});
