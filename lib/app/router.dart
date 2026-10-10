// Router simpel V.02: splash, onboarding, setup profil, setup notif, lalu 4 tab bawah.
// Beranda, Catatan, Setting, Profil. Daftar pengingat halaman sendiri via shortcut.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_tab.dart';
import '../features/reminder/reminder_tab.dart';
import '../features/reminder/reminder_form_page.dart';
import '../features/notes/notes_tab.dart';
import '../features/notes/note_editor_page.dart';
import '../features/profile/profile_tab.dart';
import '../features/setting/setting_tab.dart';
import '../features/setting/report_page.dart';
import '../features/auth/splash_page.dart';
import '../features/auth/onboarding_page.dart';
import '../features/auth/profil_setup_page.dart';
import '../features/auth/notif_setup_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashPage()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingPage()),
    GoRoute(path: '/profil-setup', builder: (c, s) => const ProfilSetupPage()),
    GoRoute(path: '/notif-setup', builder: (c, s) => const NotifSetupPage()),
    GoRoute(
        path: '/reminders',
        builder: (c, s) => Scaffold(
              appBar: AppBar(title: const Text('Daftar Pengingat')),
              body: const ReminderTab(),
            )),
    GoRoute(path: '/reminder/new', builder: (c, s) => const ReminderFormPage()),
    GoRoute(
        path: '/reminder/:id',
        builder: (c, s) => ReminderFormPage(reminderId: s.pathParameters['id'])),
    GoRoute(path: '/note/new', builder: (c, s) => const NoteEditorPage()),
    GoRoute(
        path: '/note/:id',
        builder: (c, s) => NoteEditorPage(noteId: s.pathParameters['id'])),
    GoRoute(path: '/report', builder: (c, s) => const ReportPage()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) {
        return ScaffoldWithTabs(shell: shell);
      },
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => const HomeTab())]),
        StatefulShellBranch(
            routes: [GoRoute(path: '/notes', builder: (c, s) => const NotesTab())]),
        StatefulShellBranch(
            routes: [GoRoute(path: '/setting', builder: (c, s) => const SettingTab())]),
        StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (c, s) => const ProfileTab())]),
      ],
    ),
  ],
);

class ScaffoldWithTabs extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ScaffoldWithTabs({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.note_outlined),
              selectedIcon: Icon(Icons.note),
              label: 'Catatan'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Setting'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
