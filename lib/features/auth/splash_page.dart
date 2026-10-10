// Splash loading dalam aplikasi: logo Jogoloyo, nama, spinner.
// Tugas: tunggu 2 detik, baca flag onboarding dan guru, arahkan alur yang benar.
// Tanpa data generik. Tanpa karakter terlarang.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../data/local/les_store.dart';
import '../../shared/widgets/app_logo.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});
  @override
  ConsumerState<SplashPage> createState() => _State();
}

class _State extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final onboarding = prefs.getBool('onboarding_done') ?? false;
    final guruDone = prefs.getBool('guru_setup_done') ?? false;
    List<dynamic> profiles = [];
    try {
      profiles = await ref.read(appDbProvider).select(ref.read(appDbProvider).profiles).get();
    } catch (_) {}
    if (!mounted) return;
    if (!onboarding) {
      context.go('/onboarding');
    } else if (!guruDone || profiles.isEmpty) {
      context.go('/guru-setup');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: JogloColors.paper,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 140, radius: 28),
              SizedBox(height: 16),
              Text('Les Jogoloyo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Jadwal jelas. Alarm bunyi. Data aman di HP.',
                  style: TextStyle(color: JogloColors.muted)),
              SizedBox(height: 24),
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Menyiapkan data lokal...', style: TextStyle(fontSize: 12, color: JogloColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
