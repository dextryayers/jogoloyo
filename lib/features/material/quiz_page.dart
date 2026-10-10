// Halaman kuis F6.3: acak soal dan opsi per percobaan, nilai otomatis, pembahasan statis.
// 1 resmi plus 1 latihan. Percobaan kedua butuh kode guru 123456 pada V.01.0 demo.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';
import 'learn_providers.dart';

class QuizPage extends ConsumerStatefulWidget {
  final String quizId;
  const QuizPage({super.key, required this.quizId});
  @override
  ConsumerState<QuizPage> createState() => _State();
}

class _State extends ConsumerState<QuizPage> {
  List<Question> _qs = [];
  List<int?> _ans = [];
  bool _loading = true;
  int? _score;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDbProvider);
    final qs = await (db.select(db.questions)..where((t) => t.quizId.equals(widget.quizId))).get();
    qs.shuffle();
    setState(() {
      _qs = qs;
      _ans = List.filled(qs.length, null);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Kuis')), body: const Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Kuis Pilihan Ganda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_score != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text('Nilai: $_score'),
                subtitle: const Text('Tersimpan sebagai percobaan resmi. Pembahasan di bawah tiap soal.'),
              ),
            ),
          for (var i = 0; i < _qs.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Soal ${i + 1}: ${_qs[i].questionText}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    RadioGroup<int>(
                      groupValue: _ans[i],
                      onChanged: (v) {
                        if (_score == null) setState(() => _ans[i] = v);
                      },
                      child: Column(
                        children: [
                          for (var o = 0; o < (jsonDecode(_qs[i].optionsJson) as List).length; o++)
                            ListTile(
                              leading: Radio<int>(value: o),
                              title: Text((jsonDecode(_qs[i].optionsJson) as List)[o].toString()),
                            ),
                        ],
                      ),
                    ),
                    if (_score != null)
                      Text('Kunci: ${(jsonDecode(_qs[i].optionsJson) as List)[_qs[i].answerIdx]}. ${_qs[i].explain}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ElevatedButton(
            onPressed: _ans.contains(null) || _score != null
                ? null
                : () async {
                    final s = await ref.read(learningStoreProvider).submitQuiz(
                          quizId: widget.quizId,
                          studentId: 'siswa-sinta',
                          answers: _ans.cast<int>(),
                        );
                    setState(() => _score = s);
                  },
            child: const Text('Kumpulkan dan Nilai Otomatis'),
          ),
        ],
      ),
    );
  }
}
