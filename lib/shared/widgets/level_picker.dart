// Pilih kekerasan suara plus getar. Dipakai di form pengingat,
// setup notifikasi, dan setting. Satu tampilan agar konsisten.
import 'package:flutter/material.dart';
import '../../features/schedule/alarm_prefs.dart';
import '../../app/theme.dart';

class LevelPicker extends StatelessWidget {
  final int level;
  final bool vibrate;
  final ValueChanged<int> onLevel;
  final ValueChanged<bool> onVibrate;
  const LevelPicker({
    super.key,
    required this.level,
    required this.vibrate,
    required this.onLevel,
    required this.onVibrate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kekerasan Suara', style: TextStyle(fontWeight: FontWeight.w800)),
        const Text('100 persen normal. 200 persen paling keras.',
            style: TextStyle(fontSize: 12, color: JogloColors.muted)),
        Wrap(
          spacing: 8,
          children: [
            for (final v in AlarmLevel.options)
              ChoiceChip(
                label: Text('$v%'),
                selected: level == v,
                onSelected: (_) => onLevel(v),
              ),
          ],
        ),
        SwitchListTile(
          value: vibrate,
          onChanged: onVibrate,
          title: const Text('Getar Ponsel'),
          subtitle: Text(vibrate ? 'Getar aktif saat berbunyi.' : 'Getar mati. Hanya suara.'),
        ),
      ],
    );
  }
}
