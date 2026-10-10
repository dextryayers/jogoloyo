// Splash loading: logo, spinner, arahkan alur simpel.
// onboarding -> profil (nama foto slot gender) -> notif (waktu bunyi) -> home.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../shared/widgets/app_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _State();
}

class _State extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(seconds: 2));
    final p = await SharedPreferences.getInstance();
    final onb = p.getBool('onboarding_done') ?? false;
    final prof = p.getBool('profil_done') ?? false;
    final notif = p.getBool('notif_done') ?? false;
    if (!mounted) return;
    if (!onb) {
      context.go('/onboarding');
    } else if (!prof) {
      context.go('/profil-setup');
    } else if (!notif) {
      context.go('/notif-setup');
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
              Text('Pengingat berbunyi plus catatan.',
                  style: TextStyle(color: JogloColors.muted)),
              SizedBox(height: 24),
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Menyiapkan...', style: TextStyle(fontSize: 12, color: JogloColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
