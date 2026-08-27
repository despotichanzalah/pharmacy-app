import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<dynamic> _sales = [];
  List<dynamic> _medicines = [];
  List<dynamic> _batches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.listSales(),
        ApiService.getMedicines(),
        ApiService.getAllBatches(),
      ]);
      setState(() {
        _sales = results[0];
        _medicines = results[1];
        _batches = results[2];
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  String _medicineName(dynamic id) {
    final m = _medicines.firstWhere((m) => m['id'] == id, orElse: () => null);
    return m != null ? m['name'] : '—';
  }

  Map<String, dynamic>? _batchById(dynamic id) {
    final b = _batches.firstWhere((b) => b['id'] == id, orElse: () => null);
    return b;
  }

  void _openItems(Map<String, dynamic> sale) async {
    List<dynamic> items = [];
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (loading) {
              ApiService.getSaleItems(sale['id']).then((data) {
                setSheetState(() {
                  items = data;
                  loading = false;
                });
              });
            }
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sale #${sale['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(DateTime.parse(sale['saleDate']).toLocal().toString().substring(0, 16), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                  const SizedBox(height: 16),
                  if (loading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else
                    ...items.map((it) {
                      final batch = _batchById(it['batch']?['id']);
                      final medId = batch?['medicine']?['id'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(_medicineName(medId), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            Text('${it['quantity']} × Rs ${it['price']}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
                      Text('Rs ${sale['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? const Center(child: Text('No sales recorded yet.', style: TextStyle(color: AppColors.inkSoft)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final s = _sales[i];
                      return InkWell(
                        onTap: () => _openItems(s),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sale #${s['id']} — ${s['customerName']?.toString().isNotEmpty == true ? s['customerName'] : 'Walk-in'}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    const SizedBox(height: 3),
                                    Text(DateTime.parse(s['saleDate']).toLocal().toString().substring(0, 16),
                                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if ((s['discountPercent'] ?? 0) > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                                  child: Text('-${s['discountPercent']}%', style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              Text('Rs ${s['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
