// Onboarding 3 halaman: jadwal dan alarm, guru terverifikasi, offline 100 persen.
// Tombol Lewati, Lanjut, dan Mulai. Selesai tulis flag lalu ke setup guru.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../shared/widgets/app_logo.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _State();
}

class _State extends State<OnboardingPage> {
  final _ctl = PageController();
  int _i = 0;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', true);
    if (!mounted) return;
    context.go('/guru-setup');
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      _Page(
        icon: Icons.alarm_on_outlined,
        title: 'Jadwal jelas, alarm bunyi',
        desc: 'Semua sesi tampil per minggu. Alarm H-30 dan H-10 bunyi walau aplikasi ditutup.',
      ),
      _Page(
        icon: Icons.verified_outlined,
        title: 'Guru terverifikasi',
        desc: 'Foto guru diperiksa admin. Hanya guru Terverifikasi yang bisa dijadwalkan.',
      ),
      _Page(
        icon: Icons.offline_bolt_outlined,
        title: '100 persen offline',
        desc: 'Tanpa internet dan tanpa server. Data tersimpan di HP ini plus backup ZIP.',
      ),
    ];
    return Scaffold(
      backgroundColor: JogloColors.paper,
      appBar: AppBar(
        actions: [
          TextButton(onPressed: _finish, child: const Text('Lewati')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AppLogo(size: 96),
            const SizedBox(height: 8),
            const Text('Les Jogoloyo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Expanded(
              child: PageView.builder(
                controller: _ctl,
                itemCount: pages.length,
                onPageChanged: (v) => setState(() => _i = v),
                itemBuilder: (c, i) => pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < pages.length; k++)
                  Container(
                    margin: const EdgeInsets.all(4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: k == _i ? JogloColors.primary : JogloColors.line,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_i < pages.length - 1) {
                      _ctl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    } else {
                      _finish();
                    }
                  },
                  child: Text(_i < pages.length - 1 ? 'Lanjut' : 'Mulai Setup Guru'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _Page({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: JogloColors.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: JogloColors.muted)),
        ],
      ),
    );
  }
}
