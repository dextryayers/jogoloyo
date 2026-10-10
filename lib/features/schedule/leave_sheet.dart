// Sheet izin atau sakit F2.3. Simpan ke tabel attendances lokal.
// Izin lebih dari 2 hari wajib lampiran surat (info, file menyusul Fase 6).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';

class LeaveSheet extends ConsumerStatefulWidget {
  final String sessionId;
  const LeaveSheet({super.key, required this.sessionId});
  @override
  ConsumerState<LeaveSheet> createState() => _State();
}

class _State extends ConsumerState<LeaveSheet> {
  String _kind = 'izin';
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Izin atau Sakit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Status tercatat dan tidak dihitung alpa. Guru dapat info di HP yang sama.'),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Izin'),
                  selected: _kind == 'izin',
                  onSelected: (_) => setState(() => _kind = 'izin'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Sakit'),
                  selected: _kind == 'sakit',
                  onSelected: (_) => setState(() => _kind = 'sakit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Alasan',
                hintText: 'Contoh: Ada acara keluarga di rumah.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_reason.text.trim().length < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Tulis alasan min 5 karakter agar jelas.')));
                    return;
                  }
                  final db = ref.read(appDbProvider);
                  await db.into(db.attendances).insert(
                        AttendancesCompanion.insert(
                          sessionId: widget.sessionId,
                          profileId: 'siswa-sinta',
                          status: _kind,
                        ),
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Tercatat $_kind. Sampaikan juga ke admin jika mendadak.')));
                },
                child: const Text('Kirim Izin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
