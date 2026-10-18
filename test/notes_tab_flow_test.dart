// Uji alur nyata: simpan catatan lewat store, buka tab Catatan, pastikan tampil.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jogoloyo_les/data/local/simple_store.dart';
import 'package:jogoloyo_les/features/notes/notes_tab.dart';

void main() {
  testWidgets('catatan tersimpan muncul di tab Catatan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SimpleStore();
    await store.saveNote(title: 'Catatan Uji', body: 'Isi body uji');

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: NotesTab())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catatan Uji'), findsWidgets);
    expect(find.text('Isi body uji'), findsWidgets);
  });
}