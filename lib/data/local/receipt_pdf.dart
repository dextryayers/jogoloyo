// Kwitansi PDF lokal LUNAS. Dibuat di HP, simpan ke temp, bagikan atau cetak.
// Isi: nomor, nama, periode, nominal, tanggal verifikasi, verifikator.
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'app_db.dart';

Future<File> buildReceiptPdf({
  required Bill bill,
  required String studentName,
  required String receiptNo,
}) async {
  final doc = pw.Document();
  final rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  doc.addPage(
    pw.Page(
      build: (c) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('LES JOGOLOYO', style: const pw.TextStyle(fontSize: 20)),
          pw.Text('Kwitansi Pembayaran Les'),
          pw.Divider(),
          pw.Text('Nomor: $receiptNo'),
          pw.Text('Nama: $studentName'),
          pw.Text('Periode: ${bill.period}'),
          pw.Text('Nominal: ${rp.format(bill.amountInt)}'),
          pw.Text('Status: LUNAS'),
          pw.Text('Tanggal: ${DateTime.now().toUtc().add(const Duration(hours: 7))} WIB'),
          pw.SizedBox(height: 24),
          pw.Text('Admin Les Jogoloyo'),
        ],
      ),
    ),
  );
  final tmp = await getTemporaryDirectory();
  final f = File('${tmp.path}/$receiptNo.pdf');
  await f.writeAsBytes(await doc.save());
  return f;
}

String formatRp(int n) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(n);
