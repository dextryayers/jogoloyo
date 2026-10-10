// F6 store: materi, tugas, kuis. Semua lokal dengan batas tegas.
// Materi PDF gambar maks 25 MB. Tugas kumpul maks 10 MB. Kuis PG acak.
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'app_db.dart';

class LearningStore {
  final AppDb db;
  LearningStore(this.db);

  Future<String> pickAndSaveMaterial({required String subject, required String title, bool important = false}) async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (files.isEmpty || files.single.path == null) throw Exception('Pemilihan dibatalkan.');
    final src = File(files.single.path!);
    final size = await src.length();
    if (size > 25 * 1024 * 1024) throw Exception('File di atas 25 MB. Kecilkan dulu.');
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'materi'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final id = const Uuid().v4();
    final ext = p.extension(src.path);
    final dst = File(p.join(dir.path, '$id$ext'));
    await src.copy(dst.path);
    await db.into(db.materials).insert(
          MaterialsCompanion.insert(
            id: id,
            subject: subject,
            title: title.trim(),
            kind: Value(ext.replaceFirst('.', '')),
            pathOrUrl: dst.path,
            sizeBytes: Value(size),
            important: Value(important),
          ),
        );
    return id;
  }

  Stream<List<Material>> watchMaterials(String subject) =>
      (db.select(db.materials)..where((t) => t.subject.equals(subject))..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();

  Future<List<Material>> allMaterials() => (db.select(db.materials)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();

  Future<int> storageBytes() async {
    final all = await allMaterials();
    var n = 0;
    for (final m in all) {
      n += m.sizeBytes;
    }
    return n;
  }

  Future<void> deleteMaterial(String id) async {
    final m = await (db.select(db.materials)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (m != null) {
      try {
        final f = File(m.pathOrUrl);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      await (db.delete(db.materials)..where((t) => t.id.equals(id))).go();
    }
  }

  Future<void> createAssignment({
    required String subject,
    required String title,
    required String desc,
    required DateTime dueUtc,
    int maxScore = 100,
  }) async {
    await db.into(db.assignments).insert(
          AssignmentsCompanion.insert(
            id: const Uuid().v4(),
            subject: subject,
            title: title.trim(),
            desc: Value(desc.trim()),
            dueUtc: dueUtc.toUtc(),
            maxScore: Value(maxScore),
          ),
        );
  }

  Future<void> submitAssignment({required String assignmentId, required String studentId}) async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty || files.single.path == null) throw Exception('Pemilihan dibatalkan.');
    final src = File(files.single.path!);
    if (await src.length() > 10 * 1024 * 1024) throw Exception('File di atas 10 MB.');
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'tugas'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dst = File(p.join(dir.path, '${const Uuid().v4()}_${p.basename(src.path)}'));
    await src.copy(dst.path);
    final a = await (db.select(db.assignments)..where((t) => t.id.equals(assignmentId))).getSingle();
    var status = 'terkumpul';
    if (DateTime.now().toUtc().isAfter(a.dueUtc)) status = 'terlambat';
    await db.into(db.submissions).insert(
          SubmissionsCompanion.insert(
            assignmentId: assignmentId,
            studentId: studentId,
            filePath: dst.path,
            status: Value(status),
          ),
        );
  }

  Future<void> grade(String submissionId, int score) async {
    await (db.update(db.submissions)..where((t) => t.id.equals(int.parse(submissionId)))).write(
      SubmissionsCompanion(score: Value(score), status: const Value('dinilai')),
    );
  }

  Future<void> seedQuizIfEmpty() async {
    final n = await (db.selectOnly(db.quizzes)..addColumns([db.quizzes.id.count()])).getSingle();
    if ((n.read(db.quizzes.id.count()) ?? 0) > 0) return;
    const qid = 'quiz-mat-01';
    await db.into(db.quizzes).insert(
          QuizzesCompanion.insert(id: qid, subject: 'Matematika', title: 'Kuis Bab 3: 10 soal'),
        );
    final qs = [
      ('2x + 3 = 11. x = ?', ['3', '4', '5', '6'], 1, '2x = 8 sehingga x = 4.'),
      ('Gradien y = 3x + 2 adalah?', ['2', '3', '5', 'x'], 1, 'Bentuk y = mx + c, m = 3.'),
      ('Himpunan selesai x - 5 = 0?', ['0', '5', '-5', '10'], 1, 'x = 5.'),
      ('3(x - 2) = 9. x = ?', ['4', '5', '3', '6'], 1, '3x - 6 = 9, 3x = 15, x = 5.'),
      ('Jika f(x)=2x+1, f(3)=?', ['5', '6', '7', '8'], 2, '2x3+1 = 7.'),
    ];
    for (var i = 0; i < qs.length; i++) {
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              id: const Uuid().v4(),
              quizId: qid,
              questionText: qs[i].$1,
              optionsJson: jsonEncode(qs[i].$2),
              answerIdx: qs[i].$3,
              explain: Value(qs[i].$4),
            ),
          );
    }
  }

  Future<int> submitQuiz({required String quizId, required String studentId, required List<int> answers, String kind = 'resmi'}) async {
    final qs = await (db.select(db.questions)..where((t) => t.quizId.equals(quizId))).get();
    var benar = 0;
    for (var i = 0; i < qs.length && i < answers.length; i++) {
      if (answers[i] == qs[i].answerIdx) benar++;
    }
    final score = qs.isEmpty ? 0 : (benar * 100 ~/ qs.length);
    await db.into(db.attempts).insert(
          AttemptsCompanion.insert(
            quizId: quizId,
            studentId: studentId,
            score: score,
            answersJson: jsonEncode(answers),
            kind: Value(kind),
          ),
        );
    return score;
  }
}
