// Uji asap Les Jogoloyo: splash lalu 5 tab tampil labelnya.
// Flag onboarding dan guru dilewati via mock prefs agar langsung ke /home.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jogoloyo_les/data/local/app_db.dart';
import 'package:jogoloyo_les/data/local/les_store.dart';
import 'package:jogoloyo_les/features/material/learn_providers.dart';
import 'package:jogoloyo_les/features/schedule/schedule_providers.dart';
import 'package:jogoloyo_les/main.dart';

void main() {
  testWidgets('App tampil 5 tab bawah', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'guru_setup_done': true,
      'active_profile_id': 'owner-1',
    });
    final db = AppDb.forTesting(NativeDatabase.memory());
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: 'owner-1',
            role: 'OWNER',
            name: 'Owner',
            pinHash: 'x',
            salt: 'y',
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDbProvider.overrideWithValue(db),
          weekSessionsProvider.overrideWith((ref) async => []),
          materialsProvider.overrideWith((ref) async => []),
          assignmentsProvider.overrideWith((ref) async => []),
          quizzesProvider.overrideWith((ref) async => []),
          announcementsProvider.overrideWith((ref) async => []),
        ],
        child: const JogoloyoApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Guru'), findsWidgets);
    expect(find.text('Materi'), findsWidgets);
    expect(find.text('Saya'), findsWidgets);
    await db.close();
  });
}
