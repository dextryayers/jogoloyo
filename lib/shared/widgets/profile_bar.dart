// Bar profil aktif untuk HP bersama. Warna beda per peran agar tidak salah input.
// OWNER hijau tua, ADMIN abu tua, GURU hijau, SISWA krem gelap, ORTU abu.
import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum LocalRole { owner, admin, guru, siswa, ortu }

class ActiveProfile {
  final String id;
  final String name;
  final LocalRole role;
  const ActiveProfile({required this.id, required this.name, required this.role});

  String get label {
    switch (role) {
      case LocalRole.owner:
        return 'Owner';
      case LocalRole.admin:
        return 'Admin';
      case LocalRole.guru:
        return 'Guru';
      case LocalRole.siswa:
        return 'Siswa';
      case LocalRole.ortu:
        return 'Ortu';
    }
  }
}

class ProfileBar extends StatelessWidget {
  final ActiveProfile profile;
  final VoidCallback onSwitch;
  const ProfileBar({super.key, required this.profile, required this.onSwitch});

  Color _bg(LocalRole r) {
    switch (r) {
      case LocalRole.owner:
        return JogloColors.primaryDark;
      case LocalRole.admin:
        return const Color(0xFF37474F);
      case LocalRole.guru:
        return JogloColors.primary;
      case LocalRole.siswa:
        return const Color(0xFF6D4C41);
      case LocalRole.ortu:
        return JogloColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: _bg(profile.role), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 18, color: JogloColors.ink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text(profile.label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: onSwitch,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
  }
}
