// Router 5 tab bawah dengan StatefulShellRoute. Tanpa auth server.
// Detail sesi dan form di luar shell agar ada tombol kembali yang jelas.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_tab.dart';
import '../features/schedule/schedule_tab.dart';
import '../features/schedule/session_detail_page.dart';
import '../features/schedule/session_form_page.dart';
import '../features/teacher/teacher_tab.dart';
import '../features/material/material_tab.dart';
import '../features/profile/profile_tab.dart';
import '../features/auth/setup_owner_page.dart';
import '../features/auth/pin_page.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/setup', builder: (c, s) => const SetupOwnerPage()),
    GoRoute(path: '/pin', builder: (c, s) => const PinPage()),
    GoRoute(
      path: '/schedule/new',
      builder: (c, s) => const SessionFormPage(),
    ),
    GoRoute(
      path: '/schedule/:id',
      builder: (c, s) => SessionDetailPage(sessionId: s.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (c, s) => SessionFormPage(sessionId: s.pathParameters['id']),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) {
        return ScaffoldWithTabs(shell: shell);
      },
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => const HomeTab())]),
        StatefulShellBranch(
            routes: [GoRoute(path: '/schedule', builder: (c, s) => const ScheduleTab())]),
        StatefulShellBranch(
            routes: [GoRoute(path: '/teachers', builder: (c, s) => const TeacherTab())]),
        StatefulShellBranch(
            routes: [GoRoute(path: '/materials', builder: (c, s) => const MaterialTab())]),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Jadwal'),
          NavigationDestination(
              icon: Icon(Icons.verified_outlined),
              selectedIcon: Icon(Icons.verified),
              label: 'Guru'),
          NavigationDestination(
              icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Materi'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Saya'),
        ],
      ),
    );
  }
}
