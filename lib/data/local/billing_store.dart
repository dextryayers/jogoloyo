// F7 billing lokal: tagihan massal, bukti foto, review, kwitansi data.
// Nominal integer rupiah. Unik student plus period. Tanpa hapus fisik.
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_db.dart';

class BillingError implements Exception {
  final String message;
  BillingError(this.message);
  @override
  String toString() => message;
}

class BillingStore {
  final AppDb db;
  BillingStore(this.db);

  Future<void> createBulk({required String period, required int amount, required List<String> studentIds}) async {
    if (amount <= 0) throw BillingError('Nominal harus di atas 0.');
    for (final sid in studentIds) {
      final ex = await (db.select(db.bills)..where((t) => t.studentId.equals(sid) & t.period.equals(period))).getSingleOrNull();
      if (ex != null) continue;
      await db.into(db.bills).insert(
            BillsCompanion.insert(
              id: const Uuid().v4(),
              studentId: sid,
              period: period,
              amountInt: amount,
            ),
          );
    }
  }

  Future<void> submitProof({required String billId, required String proofPath}) async {
    await (db.update(db.bills)..where((t) => t.id.equals(billId))).write(
      BillsCompanion(proofPath: Value(proofPath), status: const Value('waiting_review')),
    );
  }

  Future<void> review({required String billId, required bool approve, String? note}) async {
    if (!approve && (note ?? '').trim().length < 10) {
      throw BillingError('Alasan tolak min 10 karakter.');
    }
    await (db.update(db.bills)..where((t) => t.id.equals(billId))).write(
      BillsCompanion(
        status: Value(approve ? 'verified' : 'rejected'),
        reviewerNote: Value(note?.trim()),
      ),
    );
  }

  Future<List<Bill>> unpaid(String studentId) =>
      (db.select(db.bills)..where((t) => t.studentId.equals(studentId) & t.status.isNotIn(['verified']))).get();

  String receiptNo(String period, String id) => 'JGL-$period-${id.substring(0, 4).toUpperCase()}';

  Future<String> receiptNoSeq(String billId) async {
    final b = await (db.select(db.bills)..where((t) => t.id.equals(billId))).getSingle();
    final all = await (db.select(db.bills)..where((t) => t.period.equals(b.period))..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
    final idx = all.indexWhere((e) => e.id == billId) + 1;
    return 'JGL-${b.period}-${idx.toString().padLeft(4, '0')}';
  }

  Future<void> seedIfEmpty() async {
    final n = await (db.selectOnly(db.bills)..addColumns([db.bills.id.count()])).getSingle();
    if ((n.read(db.bills.id.count()) ?? 0) > 0) return;
    await db.into(db.bills).insert(
          BillsCompanion.insert(id: const Uuid().v4(), studentId: 'siswa-sinta', period: '2026-10', amountInt: 150000),
        );
    await db.into(db.announcements).insert(
          AnnouncementsCompanion.insert(
            id: const Uuid().v4(),
            title: 'Jadwal Sabtu tetap jalan',
            body: 'Bawa buku latihan bab 3. Datang 10 menit awal.',
          ),
        );
  }
}
