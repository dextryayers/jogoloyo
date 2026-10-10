// Entry Les Jogoloyo V.01.0 local. 100 persen lokal, tanpa SDK cloud.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() {
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
