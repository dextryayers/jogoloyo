// Detail tagihan F7.2: unggah bukti foto, review admin, kwitansi PDF LUNAS.
// Bukti kompres maks 2 MB agar paket tidak bengkak.
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';
import '../../data/local/receipt_pdf.dart';
import '../material/learn_providers.dart';

class BillDetailPage extends ConsumerWidget {
  final String billId;
  const BillDetailPage({super.key, required this.billId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tagihan')),
      body: FutureBuilder<Bill?>(
        future: (db.select(db.bills)..where((t) => t.id.equals(billId))).getSingleOrNull(),
        builder: (c, snap) {
          final b = snap.data;
          if (b == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${b.period} . ${formatRp(b.amountInt)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Status: ${b.status}'),
                      if (b.reviewerNote != null) Text('Catatan: ${b.reviewerNote}'),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final r = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (r == null) return;
                  final src = File(r.files.single.path!);
                  final docs = await getApplicationDocumentsDirectory();
                  final dst = File(p.join(docs.path, 'bukti_${const Uuid().v4()}.jpg'));
                  await src.copy(dst.path);
                  await ref.read(billingStoreProvider).submitProof(billId: b.id, proofPath: dst.path);
                  ref.invalidate(billsProvider);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bukti diterima. Admin memeriksa maks 1x24 jam.')));
                },
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Unggah Bukti Transfer'),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(billingStoreProvider).review(billId: b.id, approve: true);
                        ref.invalidate(billsProvider);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Terverifikasi. Kwitansi bisa dibuat.')));
                      },
                      child: const Text('Verifikasi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          await ref.read(billingStoreProvider).review(billId: b.id, approve: false, note: 'Bukti tidak terbaca. Foto ulang struk dengan nominal dan tanggal jelas.');
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                        }
                        ref.invalidate(billsProvider);
                      },
                      child: const Text('Tolak'),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: b.status != 'verified'
                    ? null
                    : () async {
                        final no = await ref.read(billingStoreProvider).receiptNoSeq(b.id);
                        final f = await buildReceiptPdf(
                          bill: b,
                          studentName: 'Sinta',
                          receiptNo: no,
                        );
                        await Share.shareXFiles([XFile(f.path)], text: 'Kwitansi Les Jogoloyo $no');
                      },
                icon: const Icon(Icons.receipt_outlined),
                label: const Text('Buat dan Bagikan Kwitansi PDF'),
              ),
            ],
          );
        },
      ),
    );
  }
}
