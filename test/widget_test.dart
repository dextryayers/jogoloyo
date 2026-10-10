// Uji asap V.02 simpel: splash lalu 4 tab bawah tampil.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jogoloyo_les/main.dart';

void main() {
  testWidgets('App tampil 4 tab bawah', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'profil_done': true,
      'notif_done': true,
      'user_name': 'Ustazah Rina',
    });
    await tester.pumpWidget(
      const ProviderScope(child: JogoloyoApp()),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Catatan'), findsWidgets);
    expect(find.text('Setting'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
  });
}
