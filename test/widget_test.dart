// Uji asap Les Jogoloyo: app bisa dibangun dan 5 tab tampil labelnya.
import 'package:flutter_test/flutter_test.dart';
import 'package:jogoloyo_les/main.dart';

void main() {
  testWidgets('App tampil 5 tab bawah', (tester) async {
    await tester.pumpWidget(const JogoloyoApp());
    await tester.pumpAndSettle();
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Guru'), findsWidgets);
    expect(find.text('Materi'), findsWidgets);
    expect(find.text('Saya'), findsWidgets);
  });
}
