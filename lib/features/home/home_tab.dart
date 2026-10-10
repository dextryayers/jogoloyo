// Tab Beranda: jawab 3 detik: hari ini les apa, jam berapa, di mana.
// Data mock lokal Fase 0.3. Fase 0.4 ganti ke Drift.
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/widgets/profile_bar.dart';
import '../../shared/widgets/session_card.dart';
import '../../shared/widgets/states.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final next = SessionInfo(
      id: 'sess-001',
      subject: 'Matematika kelas 8',
      teacher: 'Ustazah Rina',
      teacherVerified: true,
      startUtc: now.add(const Duration(hours: 2)),
      endUtc: now.add(const Duration(hours: 3, minutes: 30)),
      room: 'Ruang A',
      status: SessionStatus.scheduled,
      alarmOn: true,
    );
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileBar(
            profile: const ActiveProfile(id: 's1', name: 'Sinta', role: LocalRole.siswa),
            onSwitch: () {},
          ),
          const SizedBox(height: 12),
          const Text('Selamat sore, Sinta.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Les Berikutnya',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: JogloColors.muted)),
          const SizedBox(height: 8),
          SessionCard(info: next, onTap: () {}, onAlarm: () {}),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.alarm),
                  label: const Text('Atur Alarm'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Saya OTW'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const OfflineBanner(),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined, color: JogloColors.primary),
              title: const Text('Tagihan aktif: Rp150.000'),
              subtitle: const Text('SPP Okt 2026. Jatuh tempo 10 Okt.'),
              trailing: TextButton(onPressed: () {}, child: const Text('Lihat')),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.campaign_outlined, color: JogloColors.primary),
              title: const Text('Pengumuman: Jadwal Sabtu tetap jalan.'),
              subtitle: const Text('Bawa buku latihan bab 3.'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
