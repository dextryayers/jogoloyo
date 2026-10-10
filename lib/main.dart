// Entry Les Jogoloyo V.01.0 local. 100 persen lokal, tanpa SDK cloud.
// Bootstrap tegas: binding, zona Asia/Jakarta, error UI Indonesia, ProviderScope root.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app/router.dart';
import 'app/theme.dart';
import 'core/log/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  } catch (_) {
    // Tetap jalan walau data zona gagal dimuat. Waktu UTC plus offset WIB manual.
  }
  FlutterError.onError = (d) {
    AppLog.record('flutter_error', '${d.exception}');
    FlutterError.presentError(d);
  };
  ErrorWidget.builder = (d) => Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Terjadi galat tampilan. Tutup lalu buka lagi. Jika berulang, hubungi admin.\n\n${d.exception}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
  runApp(const ProviderScope(child: JogoloyoApp()));
}

class JogoloyoApp extends StatelessWidget {
  const JogoloyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Les Jogoloyo',
      theme: jogloTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
