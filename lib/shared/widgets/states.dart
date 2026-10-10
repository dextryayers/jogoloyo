// Empty dan error yang spesifik. Tanpa ilustrasi generik.
// Setiap empty wajib ada 1 aksi utama.
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String desc;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.title,
    required this.desc,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.event_note,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: JogloColors.scheduledBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: JogloColors.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: JogloColors.muted)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: JogloColors.danger, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () {}, child: const Text('Hubungi Admin')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: JogloColors.scheduledBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: JogloColors.line),
      ),
      child: const Text(
        'Data tersimpan di HP ini. Terakhir backup: belum pernah. Buka Saya lalu Backup.',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}
