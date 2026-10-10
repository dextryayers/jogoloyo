// Tab Guru: daftar ACTIVE plus antrian review untuk admin.
// Menegakkan kebijakan wajib berjilbab lewat status verifikasi.
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class TeacherTab extends StatelessWidget {
  const TeacherTab({super.key});
  @override
  Widget build(BuildContext context) {
    final teachers = [
      {'name': 'Ustazah Rina', 'mapel': 'Matematika', 'status': 'ACTIVE'},
      {'name': 'Ustazah Dewi', 'mapel': 'Biologi', 'status': 'ACTIVE'},
      {'name': 'Ustazah Sari', 'mapel': 'Fisika', 'status': 'PENDING'},
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Guru Jogoloyo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Hanya guru Terverifikasi yang bisa dijadwalkan.',
              style: TextStyle(color: JogloColors.muted)),
          const SizedBox(height: 12),
          for (final t in teachers)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(t['name']!),
                subtitle: Text('${t['mapel']}'),
                trailing: t['status'] == 'ACTIVE'
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: JogloColors.scheduledBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Terverifikasi',
                            style: TextStyle(
                                color: JogloColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: JogloColors.izinBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Menunggu review',
                            style: TextStyle(
                                color: JogloColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                onTap: () {},
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_outlined, color: JogloColors.primary),
              title: const Text('Antrian Review (Admin): 1 menunggu'),
              subtitle: const Text('Foto diperiksa manusia, bukan AI. Maks 1x24 jam.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
