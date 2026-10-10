// Tab Materi: struktur mapel, tugas, kuis. Offline first.
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/widgets/states.dart';

class MaterialTab extends StatelessWidget {
  const MaterialTab({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Materi dan Tugas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const OfflineBanner(),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: JogloColors.danger),
              title: const Text('Matematika: Bab 3 Persamaan Linear'),
              subtitle: const Text('PDF 4,2 MB . Diunduh . Revisi 2'),
              trailing: const Icon(Icons.download_done),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment_outlined, color: JogloColors.primary),
              title: const Text('Tugas: 10 soal latihan bab 3'),
              subtitle: const Text('Tenggat: Senin, 20 Okt 2026 23.59 WIB . Belum kumpul'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.quiz_outlined, color: JogloColors.primary),
              title: const Text('Kuis: 10 soal pilihan ganda'),
              subtitle: const Text('Nilai terakhir: 80 . 1 percobaan resmi'),
              trailing: ElevatedButton(onPressed: () {}, child: const Text('Mulai')),
            ),
          ),
        ],
      ),
    );
  }
}
