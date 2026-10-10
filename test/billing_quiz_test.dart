// Uji billing dan kuis dengan DB memori. Tanpa HP, tanpa file.
// Memastikan dobel dicegah, tolak butuh alasan, nilai otomatis benar.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jogoloyo_les/data/local/app_db.dart';
import 'package:jogoloyo_les/data/local/billing_store.dart';
import 'package:jogoloyo_les/data/local/learning_store.dart';

Future<AppDb> _mem() async {
  final db = AppDb.forTesting(NativeDatabase.memory());
  // Buat profil siswa dummy untuk foreign key bills dan submissions.
  await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          id: 'siswa-sinta',
          role: 'SISWA',
          name: 'Sinta',
          pinHash: 'x',
          salt: 'y',
        ),
      );
  return db;
}

void main() {
  test('tagihan dobel dilewati, tolak tanpa alasan ditolak', () async {
    final db = await _mem();
    final b = BillingStore(db);
    await b.createBulk(period: '2026-10', amount: 150000, studentIds: ['siswa-sinta']);
    await b.createBulk(period: '2026-10', amount: 150000, studentIds: ['siswa-sinta']);
    final all = await (db.select(db.bills)).get();
    expect(all.length, 1);
    expect(b.receiptNo('2026-10', all.first.id).startsWith('JGL-2026-10-'), true);
    var threw = false;
    try {
      await b.review(billId: all.first.id, approve: false, note: 'jelek');
    } catch (_) {
      threw = true;
    }
    expect(threw, true);
    await db.close();
  });

  test('kuis 5 soal benar 4 nilai 80', () async {
    final db = await _mem();
    final l = LearningStore(db);
    await l.seedQuizIfEmpty();
    final qs = await (db.select(db.questions)).get();
    expect(qs.length >= 5, true);
    final answers = qs.map((e) => e.answerIdx).toList();
    answers[0] = (answers[0] + 1) % 4;
    final score = await l.submitQuiz(quizId: qs.first.quizId, studentId: 'siswa-sinta', answers: answers);
    final expectScore = ((qs.length - 1) * 100 ~/ qs.length);
    expect(score, expectScore);
    await db.close();
  });
}
