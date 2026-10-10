// Kartu sesi: komponen paling penting. Tegas, padat, tanpa dekorasi.
// Menjawab dalam 3 detik: mapel apa, jam berapa, di mana, siapa gurunya.
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/time/wib.dart';

enum SessionStatus { scheduled, ongoing, done, cancelled }

class SessionInfo {
  final String id;
  final String subject;
  final String teacher;
  final bool teacherVerified;
  final DateTime startUtc;
  final DateTime endUtc;
  final String room;
  final SessionStatus status;
  final bool alarmOn;
  const SessionInfo({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.teacherVerified,
    required this.startUtc,
    required this.endUtc,
    required this.room,
    required this.status,
    required this.alarmOn,
  });
}

class SessionCard extends StatelessWidget {
  final SessionInfo info;
  final VoidCallback? onTap;
  final VoidCallback? onAlarm;
  const SessionCard({super.key, required this.info, this.onTap, this.onAlarm});

  Color _bar(SessionStatus s) {
    switch (s) {
      case SessionStatus.ongoing:
        return JogloColors.success;
      case SessionStatus.done:
        return JogloColors.muted;
      case SessionStatus.cancelled:
        return JogloColors.danger;
      case SessionStatus.scheduled:
        return JogloColors.primary;
    }
  }

  String _label(SessionStatus s) {
    switch (s) {
      case SessionStatus.ongoing:
        return 'Berlangsung';
      case SessionStatus.done:
        return 'Selesai';
      case SessionStatus.cancelled:
        return 'Batal';
      case SessionStatus.scheduled:
        return 'Terjadwal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 108,
              decoration: BoxDecoration(
                color: _bar(info.status),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            info.subject,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusChip(label: _label(info.status), status: info.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Wib.range(info.startUtc, info.endUtc),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${info.teacher}${info.teacherVerified ? ' . Terverifikasi' : ''} . ${info.room}',
                      style: const TextStyle(color: JogloColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: info.alarmOn ? 'Alarm aktif' : 'Alarm mati',
              icon: Icon(
                info.alarmOn ? Icons.alarm_on : Icons.alarm_add,
                color: info.alarmOn ? JogloColors.primary : JogloColors.muted,
              ),
              onPressed: onAlarm,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final SessionStatus status;
  const _StatusChip({required this.label, required this.status});
  @override
  Widget build(BuildContext context) {
    Color bg = JogloColors.scheduledBg;
    Color fg = JogloColors.primaryDark;
    if (status == SessionStatus.cancelled) {
      bg = JogloColors.cancelledBg;
      fg = JogloColors.danger;
    }
    if (status == SessionStatus.done) {
      bg = const Color(0xFFEEEEEE);
      fg = JogloColors.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
