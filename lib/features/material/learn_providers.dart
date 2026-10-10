// Provider belajar dan billing untuk UI.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_db.dart';
import '../../data/local/billing_store.dart';
import '../../data/local/learning_store.dart';
import '../../data/local/les_store.dart';

final learningStoreProvider = Provider((ref) => LearningStore(ref.watch(appDbProvider)));
final billingStoreProvider = Provider((ref) => BillingStore(ref.watch(appDbProvider)));

final materialsProvider = FutureProvider<List<Material>>((ref) async {
  await ref.watch(learningStoreProvider).seedQuizIfEmpty();
  await ref.watch(billingStoreProvider).seedIfEmpty();
  return ref.watch(learningStoreProvider).allMaterials();
});

final assignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final db = ref.watch(appDbProvider);
  return (db.select(db.assignments)..orderBy([(t) => OrderingTerm(expression: t.dueUtc)])).get();
});

final quizzesProvider = FutureProvider<List<Quizze>>((ref) async {
  final db = ref.watch(appDbProvider);
  await ref.watch(learningStoreProvider).seedQuizIfEmpty();
  return (db.select(db.quizzes)).get();
});

final billsProvider = FutureProvider<List<Bill>>((ref) async {
  final db = ref.watch(appDbProvider);
  await ref.watch(billingStoreProvider).seedIfEmpty();
  return (db.select(db.bills)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final db = ref.watch(appDbProvider);
  await ref.watch(billingStoreProvider).seedIfEmpty();
  return (db.select(db.announcements)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
});
