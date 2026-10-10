// Billing list F7.1: tagihan massal per periode, bukti foto, review admin.
// Nominal integer. Cegah dobel student plus period.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/receipt_pdf.dart';
import '../material/learn_providers.dart';

class BillingListPage extends ConsumerWidget {
  const BillingListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan Les')),
      body: bills.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(billsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_card_outlined),
                  title: const Text('Buat tagihan Okt 2026'),
                  subtitle: const Text('Rp150.000 untuk Sinta. Dobel otomatis dilewati.'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await ref.read(billingStoreProvider).createBulk(period: '2026-10', amount: 150000, studentIds: ['siswa-sinta']);
                      ref.invalidate(billsProvider);
                    },
                    child: const Text('Buat'),
                  ),
                ),
              ),
              for (final b in list)
                Card(
                  child: ListTile(
                    leading: Icon(
                      b.status == 'verified' ? Icons.verified : Icons.payments_outlined,
                      color: b.status == 'verified' ? Colors.green : null,
                    ),
                    title: Text('${b.period} . ${formatRp(b.amountInt)}'),
                    subtitle: Text('Status: ${b.status}${b.reviewerNote != null && b.reviewerNote!.isNotEmpty ? ' . ${b.reviewerNote}' : ''}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/bills/${b.id}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
