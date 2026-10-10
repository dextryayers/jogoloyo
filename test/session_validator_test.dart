// Uji validator bentrok jadwal: 20 kasus inti diringkas ke kasus kunci.
// Aturan: overlap [start, end) untuk teacher sama atau room sama ditolak.
import 'package:flutter_test/flutter_test.dart';
import 'package:jogoloyo_les/data/local/session_repo.dart';

SessionInput s(String id, String t, String room, int sh, int eh) {
  final d = DateTime.utc(2026, 10, 18);
  return SessionInput(
    id: id,
    subject: 'Mapel $id',
    teacherId: t,
    startUtc: d.add(Duration(hours: sh)),
    endUtc: d.add(Duration(hours: eh)),
    room: room,
  );
}

void main() {
  test('tidak bentrok jika beda guru beda ruang', () {
    final a = s('a', 'g1', 'Ruang A', 8, 10);
    SessionValidator.checkNoOverlap(s('b', 'g2', 'Ruang B', 9, 11), [a]);
  });

  test('bentrok guru sama overlap ditolak', () {
    final a = s('a', 'g1', 'Ruang A', 8, 10);
    expect(
      () => SessionValidator.checkNoOverlap(s('b', 'g1', 'Ruang B', 9, 11), [a]),
      throwsA(isA<OverlapError>()),
    );
  });

  test('bentrok ruang sama overlap ditolak', () {
    final a = s('a', 'g1', 'Ruang A', 8, 10);
    expect(
      () => SessionValidator.checkNoOverlap(s('b', 'g2', 'Ruang A', 9, 11), [a]),
      throwsA(isA<OverlapError>()),
    );
  });

  test('melepet tepat tidak bentrok: akhir sama dengan mulai', () {
    final a = s('a', 'g1', 'Ruang A', 8, 10);
    SessionValidator.checkNoOverlap(s('b', 'g1', 'Ruang A', 10, 12), [a]);
  });

  test('jam selesai sebelum mulai ditolak', () {
    expect(
      () => SessionValidator.checkNoOverlap(s('b', 'g1', 'Ruang A', 12, 10), []),
      throwsA(isA<OverlapError>()),
    );
  });
}
