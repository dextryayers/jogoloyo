// Router 5 tab bawah dengan StatefulShellRoute. Tanpa auth server.
// Detail sesi dan form di luar shell agar ada tombol kembali yang jelas.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_tab.dart';
import '../features/schedule/schedule_tab.dart';
import '../features/schedule/session_detail_page.dart';
import '../features/schedule/session_form_page.dart';
import '../features/teacher/teacher_tab.dart';
import '../features/teacher/teacher_detail_page.dart';
import '../features/teacher/teacher_submit_page.dart';
import '../features/teacher/review_queue_page.dart';
import '../features/teacher/checkin_page.dart';
import '../features/attendance/attendance_page.dart';
import '../features/attendance/qr_display_page.dart';
import '../features/attendance/qr_scan_page.dart';
import '../features/material/material_tab.dart';
import '../features/material/quiz_page.dart';
import '../features/material/assignment_page.dart';
import '../features/billing/billing_list_page.dart';
import '../features/billing/bill_detail_page.dart';
import '../features/profile/sync_backup_page.dart';
import '../features/profile/wipe_page.dart';
import '../features/profile/profile_tab.dart';
import '../features/auth/setup_owner_page.dart';
import '../features/auth/pin_page.dart';
import '../features/auth/startup_gate.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const StartupGate()),
    GoRoute(path: '/setup', builder: (c, s) => const SetupOwnerPage()),
    GoRoute(path: '/pin', builder: (c, s) => const PinPage()),
    GoRoute(path: '/schedule/new', builder: (c, s) => const SessionFormPage()),
    GoRoute(
      path: '/schedule/:id',
      builder: (c, s) => SessionDetailPage(sessionId: s.pathParameters['id']!),
      routes: [
        GoRoute(path: 'edit', builder: (c, s) => SessionFormPage(sessionId: s.pathParameters['id'])),
      ],
    ),
    GoRoute(path: '/teachers/submit', builder: (c, s) => const TeacherSubmitPage()),
    GoRoute(path: '/teachers/review', builder: (c, s) => const ReviewQueuePage()),
    GoRoute(path: '/teachers/:id', builder: (c, s) => TeacherDetailPage(teacherId: s.pathParameters['id']!)),
    GoRoute(
      path: '/checkin/:sid/:tid',
      builder: (c, s) => CheckinPage(
        sessionId: s.pathParameters['sid']!,
        teacherId: s.pathParameters['tid']!,
      ),
    ),
    GoRoute(path: '/attendance/:id', builder: (c, s) => AttendancePage(sessionId: s.pathParameters['id']!)),
    GoRoute(path: '/attendance/:id/qr', builder: (c, s) => QrDisplayPage(sessionId: s.pathParameters['id']!)),
    GoRoute(path: '/attendance/:id/scan', builder: (c, s) => QrScanPage(sessionId: s.pathParameters['id']!)),
    GoRoute(path: '/quiz/:id', builder: (c, s) => QuizPage(quizId: s.pathParameters['id']!)),
    GoRoute(path: '/assignments/:id', builder: (c, s) => AssignmentPage(assignmentId: s.pathParameters['id']!)),
    GoRoute(path: '/bills', builder: (c, s) => const BillingListPage()),
    GoRoute(path: '/bills/:id', builder: (c, s) => BillDetailPage(billId: s.pathParameters['id']!)),
    GoRoute(path: '/sync', builder: (c, s) => const SyncBackupPage()),
    GoRoute(path: '/wipe', builder: (c, s) => const WipePage()),
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
