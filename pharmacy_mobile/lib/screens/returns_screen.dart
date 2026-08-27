import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  List<dynamic> _sales = [];
  List<dynamic> _medicines = [];
  List<dynamic> _batches = [];
  Map<String, dynamic>? _selectedSale;
  List<dynamic> _saleItems = [];
  final Map<int, int> _returnQty = {}; // saleItemId -> quantity to return
  final _reasonController = TextEditingController();

  bool _loadingSales = true;
  bool _loadingItems = false;
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _loadingSales = true);
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
      setState(() => _loadingSales = false);
    }
  }

  String _medicineName(dynamic id) {
    final m = _medicines.firstWhere((m) => m['id'] == id, orElse: () => null);
    return m != null ? m['name'] : '—';
  }

  Map<String, dynamic>? _batchById(dynamic id) {
    return _batches.firstWhere((b) => b['id'] == id, orElse: () => null);
  }

  Future<void> _selectSale(Map<String, dynamic> sale) async {
    setState(() {
      _selectedSale = sale;
      _saleItems = [];
      _returnQty.clear();
      _loadingItems = true;
      _error = null;
      _success = null;
    });
    try {
      final items = await ApiService.getSaleItems(sale['id']);
      setState(() => _saleItems = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingItems = false);
    }
  }

  Future<void> _submitReturn() async {
    final items = _returnQty.entries
        .where((e) => e.value > 0)
        .map((e) => {'saleItemId': e.key, 'quantity': e.value})
        .toList();

    if (items.isEmpty) {
      setState(() => _error = 'Enter a quantity to return for at least one item.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    try {
      final result = await ApiService.createReturn(
        saleId: _selectedSale!['id'],
        reason: _reasonController.text.trim(),
        items: items,
      );
      setState(() {
        _success = 'Return processed — refund Rs ${result['refundAmount']}';
        _selectedSale = null;
        _saleItems = [];
        _returnQty.clear();
        _reasonController.clear();
      });
      _loadSales();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Returns')),
      body: _loadingSales
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(13),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFFDEAEA), borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: const TextStyle(color: AppColors.bad)),
                  ),
                if (_success != null)
                  Container(
                    padding: const EdgeInsets.all(13),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFEAF7F0), borderRadius: BorderRadius.circular(10)),
                    child: Text(_success!, style: const TextStyle(color: AppColors.good, fontWeight: FontWeight.w600)),
                  ),

                const Text('Find the sale', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                if (_sales.isEmpty)
                  const Text('No sales recorded yet.', style: TextStyle(color: AppColors.inkSoft))
                else
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedSale,
                    decoration: const InputDecoration(labelText: 'Sale'),
                    items: _sales.cast<Map<String, dynamic>>().map((s) {
                      final label = 'Sale #${s['id']} — ${s['customerName']?.toString().isNotEmpty == true ? s['customerName'] : 'Walk-in'} — Rs ${s['totalAmount']}';
                      return DropdownMenuItem<Map<String, dynamic>>(value: s, child: Text(label, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) _selectSale(v);
                    },
                  ),

                if (_loadingItems) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator())),

                if (_saleItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Items in this sale', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  ..._saleItems.map((it) {
                    final batch = _batchById(it['batch']?['id']);
                    final medName = _medicineName(batch?['medicine']?['id']);
                    final soldQty = it['quantity'] as int;
                    final saleItemId = it['id'] as int;
                    final currentReturn = _returnQty[saleItemId] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(medName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text('Sold: $soldQty × Rs ${it['price']}', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Return qty', isDense: true),
                              onChanged: (v) {
                                final qty = int.tryParse(v) ?? 0;
                                setState(() => _returnQty[saleItemId] = qty.clamp(0, soldQty));
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextField(controller: _reasonController, decoration: const InputDecoration(labelText: 'Reason (optional)')),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitReturn,
                      child: Text(_submitting ? 'Processing…' : 'Process return'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
