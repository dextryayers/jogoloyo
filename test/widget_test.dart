// Uji asap Les Jogoloyo: app bisa dibangun dan 5 tab tampil labelnya.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jogoloyo_les/features/schedule/schedule_providers.dart';
import 'package:jogoloyo_les/main.dart';

void main() {
  testWidgets('App tampil 5 tab bawah', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weekSessionsProvider.overrideWith((ref) async => []),
        ],
        child: const JogoloyoApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Guru'), findsWidgets);
    expect(find.text('Materi'), findsWidgets);
    expect(find.text('Saya'), findsWidgets);
  });
}
