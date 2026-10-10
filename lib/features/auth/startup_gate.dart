// Gerbang startup: cek owner di DB lokal. Kosong ke /setup, ada ke /home.
// Mencegah app dibuka tanpa setup. Tanpa server, tanpa loading generik.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/les_store.dart';

class StartupGate extends ConsumerWidget {
  const StartupGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDbProvider);
    return FutureBuilder(
      future: (db.select(db.profiles)).get(),
      builder: (c, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final hasOwner = snap.data!.any((e) => e.role == 'OWNER');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasOwner) {
            context.go('/home');
          } else {
            context.go('/setup');
          }
        });
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Menyiapkan data lokal...'),
              ],
            ),
          ),
        );
      },
    );
  }
}
