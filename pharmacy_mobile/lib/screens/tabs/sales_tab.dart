import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../main.dart';
import '../../services/api_service.dart';

// A cart line: batch + quantity + a display label (e.g. "Panadol — Batch B1")
class _CartLine {
  final Map<String, dynamic> batch;
  final String medicineName;
  int quantity;
  _CartLine({required this.batch, required this.medicineName, required this.quantity});

  double get lineTotal => quantity * (batch['salePrice'] as num).toDouble();
}

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  List<dynamic> _medicines = [];
  List<dynamic> _batches = [];
  final List<_CartLine> _cart = [];
  final _customerController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  bool _loading = true;
  bool _checkingOut = false;
  String? _error;
  Map<String, dynamic>? _lastReceipt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getMedicines(), ApiService.getAllBatches()]);
      setState(() {
        _medicines = results[0];
        _batches = (results[1] as List).where((b) => (b['quantity'] ?? 0) > 0).toList();
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  // Called by DashboardScreen every time this tab becomes visible, so a
  // newly added medicine and its current stock are never stale here.
  void reload() => _load();

  String _medicineName(dynamic medicineId) {
    final m = _medicines.firstWhere((m) => m['id'] == medicineId, orElse: () => null);
    return m != null ? m['name'] : '#$medicineId';
  }

  List<dynamic> _batchesForMedicine(int medicineId) {
    return _batches.where((b) => b['medicine']?['id'] == medicineId).toList();
  }

  // Searches both medicine names and generic names, matching the web app's search.
  Iterable<dynamic> _searchMedicines(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return const Iterable.empty();
    return _medicines.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final generics = ((m['generics'] as List?) ?? []).map((g) => (g['name'] ?? '').toString().toLowerCase());
      return name.contains(q) || generics.any((g) => g.contains(q));
    });
  }

  void _addToCart(Map<String, dynamic> batch, int quantity, String medicineName) {
    final existing = _cart.where((c) => c.batch['id'] == batch['id']).firstOrNull;
    setState(() {
      if (existing != null) {
        existing.quantity += quantity;
      } else {
        _cart.add(_CartLine(batch: batch, medicineName: medicineName, quantity: quantity));
      }
    });
  }

  double get _subtotal => _cart.fold(0, (sum, c) => sum + c.lineTotal);
  double get _discountPercent => double.tryParse(_discountController.text) ?? 0;
  double get _discountAmount => _subtotal * _discountPercent / 100;
  double get _total => _subtotal - _discountAmount;

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    setState(() {
      _checkingOut = true;
      _error = null;
    });
    try {
      final result = await ApiService.createSale(
        customerName: _customerController.text.trim(),
        discountPercent: _discountPercent,
        items: _cart.map((c) => {'batchId': c.batch['id'], 'quantity': c.quantity}).toList(),
      );
      final receiptItems = _cart.map((c) => {
            'medicineName': c.medicineName,
            'quantity': c.quantity,
            'price': (c.batch['salePrice'] as num).toDouble(),
            'lineTotal': c.lineTotal,
          }).toList();
      setState(() {
        _lastReceipt = {
          'sale': result,
          'items': receiptItems,
          'customerName': _customerController.text.trim(),
          'discountPercent': _discountPercent,
          'subtotal': _subtotal,
        };
        _cart.clear();
        _customerController.clear();
        _discountController.text = '0';
      });
      _load();
      if (mounted) _showReceipt();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  // Builds a narrow (80mm) receipt PDF, matching the web app's thermal-printer sizing,
  // and hands it to Android's native print/share sheet (works with connected printers,
  // or lets the user save/share it as a PDF).
  Future<Uint8List> _buildReceiptPdf() async {
    final sale = _lastReceipt!['sale'];
    final items = _lastReceipt!['items'] as List;
    final discountPercent = _lastReceipt!['discountPercent'] as double;
    final subtotal = _lastReceipt!['subtotal'] as double;
    final customerName = _lastReceipt!['customerName'] as String;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 8 * PdfPageFormat.mm),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(child: pw.Text('Huny Pharmacy', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('Sale #${sale['id']}', style: const pw.TextStyle(fontSize: 9))),
            if (customerName.isNotEmpty) pw.Center(child: pw.Text('Customer: $customerName', style: const pw.TextStyle(fontSize: 9))),
            pw.Divider(),
            ...items.map((it) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('${it['medicineName']} x${it['quantity']}', style: const pw.TextStyle(fontSize: 9))),
                      pw.Text('Rs ${(it['lineTotal'] as double).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                )),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Rs ${subtotal.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            if (discountPercent > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discount ($discountPercent%)', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('- Rs ${(subtotal * discountPercent / 100).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs ${sale['totalAmount']}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  void _showReceipt() {
    if (_lastReceipt == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final sale = _lastReceipt!['sale'];
        final items = _lastReceipt!['items'] as List;
        final discountPercent = _lastReceipt!['discountPercent'] as double;
        final subtotal = _lastReceipt!['subtotal'] as double;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              // Narrow width like an 80mm thermal receipt, not a full A4 page.
              constraints: const BoxConstraints(maxWidth: 300),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.good, size: 40),
                    const SizedBox(height: 10),
                    const Text('Sale complete', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Huny Pharmacy', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
                          Text('Sale #${sale['id']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                          const Divider(height: 20),
                          ...items.map((it) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Expanded(child: Text('${it['medicineName']} ×${it['quantity']}', style: const TextStyle(fontSize: 12))),
                                    Text('Rs ${(it['lineTotal'] as double).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              )),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Text('Subtotal', style: TextStyle(fontSize: 12))),
                              Text('Rs ${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          if (discountPercent > 0)
                            Row(
                              children: [
                                Expanded(child: Text('Discount ($discountPercent%)', style: const TextStyle(fontSize: 12, color: AppColors.bad))),
                                Text('- Rs ${(subtotal * discountPercent / 100).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.bad)),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
                              Text('Rs ${sale['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final bytes = await _buildReceiptPdf();
                              await Printing.layoutPdf(onLayout: (_) async => bytes);
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Print / Share'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFFFDEAEA), borderRadius: BorderRadius.circular(10)),
            child: Text(_error!, style: const TextStyle(color: AppColors.bad)),
          ),

        // Medicine search — type a brand or generic name, no scrolling through hundreds of items.
        Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (value) => _searchMedicines(value.text).cast<Map<String, dynamic>>(),
          displayStringForOption: (m) => m['name'],
          fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Search medicine or generic…', prefixIcon: Icon(Icons.search)),
            );
          },
          optionsViewBuilder: (ctx, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: options.map((m) {
                      final generics = ((m['generics'] as List?) ?? []).map((g) => g['name']).join(', ');
                      return ListTile(
                        title: Text(m['name']),
                        subtitle: generics.isNotEmpty ? Text(generics, style: const TextStyle(fontSize: 11)) : null,
                        onTap: () => onSelected(m),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
          onSelected: (medicine) => _openBatchPicker(medicine),
        ),
        const SizedBox(height: 20),

        const Text('Cart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 10),
        if (_cart.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Cart is empty.', style: TextStyle(color: AppColors.inkSoft)))
        else
          ..._cart.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.medicineName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('${c.quantity} × Rs ${c.batch['salePrice']}', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    Text('Rs ${c.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.bad),
                      onPressed: () => setState(() => _cart.remove(c)),
                    ),
                  ],
                ),
              )),

        const SizedBox(height: 16),
        TextField(controller: _customerController, decoration: const InputDecoration(labelText: 'Customer name (optional)')),
        const SizedBox(height: 12),
        TextField(
          controller: _discountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Discount %', suffixText: '%'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Subtotal')),
                  Text('Rs ${_subtotal.toStringAsFixed(0)}'),
                ],
              ),
              if (_discountPercent > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('Discount (${_discountPercent.toStringAsFixed(0)}%)', style: const TextStyle(color: AppColors.bad))),
                      Text('- Rs ${_discountAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.bad)),
                    ],
                  ),
                ),
              const Divider(height: 20),
              Row(
                children: [
                  const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  Text('Rs ${_total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_checkingOut || _cart.isEmpty) ? null : _checkout,
            child: Text(_checkingOut ? 'Processing…' : 'Complete sale'),
          ),
        ),
      ],
    );
  }

  void _openBatchPicker(Map<String, dynamic> medicine) {
    final batches = _batchesForMedicine(medicine['id']);
    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No stock available for ${medicine['name']}.')));
      return;
    }
    Map<String, dynamic>? selectedBatch = batches.length == 1 ? batches.first : null;
    final qtyController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                if (batches.length > 1)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selectedBatch,
                    decoration: const InputDecoration(labelText: 'Batch'),
                    items: batches
                        .cast<Map<String, dynamic>>()
                        .map((b) => DropdownMenuItem<Map<String, dynamic>>(value: b, child: Text('${b['batchNumber']} — ${b['quantity']} left — Rs ${b['salePrice']}')))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedBatch = v),
                  )
                else
                  Text('Batch ${batches.first['batchNumber']} — ${batches.first['quantity']} left — Rs ${batches.first['salePrice']}/unit',
                      style: const TextStyle(color: AppColors.inkSoft)),
                const SizedBox(height: 16),
                TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final b = selectedBatch ?? batches.first;
                      final qty = int.tryParse(qtyController.text) ?? 1;
                      _addToCart(b, qty, medicine['name']);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add to cart'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
