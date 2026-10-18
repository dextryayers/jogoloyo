// Uji alur notepad dari ujung ke ujung lewat UI nyata.
// Tulis di editor, simpan, lalu pastikan catatan muncul di tab Catatan.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jogoloyo_les/data/local/simple_store.dart';
import 'package:jogoloyo_les/main.dart';

void main() {
  testWidgets('tulis catatan, simpan, lalu muncul di tab Catatan',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'profil_done': true,
      'notif_done': true,
      'user_name': 'Ustazah Rina',
      'app_version': '1.0.0+1',
    });

    await tester.pumpWidget(const ProviderScope(child: JogoloyoApp()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    // Masuk tab Catatan.
    await tester.tap(find.text('Catatan').last);
    await tester.pumpAndSettle();

    // Tulis catatan baru lewat tombol di layar kosong.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tulis'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Judul'),
      'Catatan Uji',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tulis di sini...'),
      'Isi body catatan uji',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // Catatan harus ada di daftar dan bisa dibuka lagi utuh.
    expect(find.text('Catatan Uji'), findsWidgets);

    // Buka lagi, isi harus sama persis.
    await tester.tap(find.text('Catatan Uji').first);
    await tester.pumpAndSettle();
    expect(find.text('Isi body catatan uji'), findsOneWidget);

    final store = SimpleStore();
    final notes = await store.loadNotes();
    expect(notes.length, 1);
    expect(notes.first.title, 'Catatan Uji');
    expect(notes.first.body, 'Isi body catatan uji');
  });
}