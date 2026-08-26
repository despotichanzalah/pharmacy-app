import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  List<dynamic> _medicines = [];
  List<dynamic> _batches = [];
  List<_CartLine> _cart = [];
  int? _pickBatchId;
  String _pickMode = 'units'; // units | packs
  final _qtyController = TextEditingController(text: '1');
  final _customerController = TextEditingController();
  final _discountController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _customerController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getMedicines(),
        ApiService.getAllBatches(),
      ]);
      setState(() {
        _medicines = results[0] as List<dynamic>;
        _batches = (results[1] as List<dynamic>).where((b) => (b['quantity'] ?? 0) > 0).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _medicineName(dynamic medicineId) {
    final m = _medicines.cast<dynamic>().where((x) => x['id'] == medicineId).toList();
    return m.isNotEmpty ? m.first['name'] : '#$medicineId';
  }

  int _packSizeFor(dynamic medicineId) {
    final m = _medicines.cast<dynamic>().where((x) => x['id'] == medicineId).toList();
    return m.isNotEmpty ? (m.first['packSize'] ?? 1) as int : 1;
  }

  Map<String, dynamic>? get _pickedBatch {
    if (_pickBatchId == null) return null;
    final matches = _batches.where((b) => b['id'] == _pickBatchId).toList();
    return matches.isEmpty ? null : Map<String, dynamic>.from(matches.first);
  }

  double get _subtotal => _cart.fold(0, (sum, c) => sum + c.quantity * c.salePrice);

  double get _discountPercent {
    final v = double.tryParse(_discountController.text.trim()) ?? 0;
    if (v < 0) return 0;
    if (v > 100) return 100;
    return v;
  }

  double get _discountAmount => _subtotal * _discountPercent / 100;
  double get _total => _subtotal - _discountAmount;

  void _addToCart() {
    final batch = _pickedBatch;
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (batch == null || qty < 1) return;

    final medicineId = batch['medicine']?['id'];
    final packSize = _packSizeFor(medicineId);
    final unitQty = _pickMode == 'packs' ? qty * packSize : qty;
    final available = batch['quantity'] ?? 0;
    if (unitQty > available) {
      setState(() => _error = 'Only $available units left in this batch.');
      return;
    }

    setState(() {
      _error = null;
      _success = null;
      final existing = _cart.indexWhere((c) => c.batchId == batch['id']);
      if (existing >= 0) {
        _cart[existing] = _cart[existing].copyWith(quantity: _cart[existing].quantity + unitQty);
      } else {
        _cart.add(_CartLine(
          batchId: batch['id'],
          medicineId: medicineId,
          medicineName: _medicineName(medicineId),
          batchNumber: batch['batchNumber'] ?? '',
          quantity: unitQty,
          salePrice: (batch['salePrice'] as num).toDouble(),
        ));
      }
      _pickBatchId = null;
      _pickMode = 'units';
      _qtyController.text = '1';
    });
  }

  Future<void> _completeSale() async {
    setState(() {
      _error = null;
      _success = null;
    });
    if (_cart.isEmpty) {
      setState(() => _error = 'Add at least one item to the cart.');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = await ApiService.createSale(
        customerName: _customerController.text.trim(),
        discountPercent: _discountPercent,
        items: _cart.map((c) => {'batchId': c.batchId, 'quantity': c.quantity}).toList(),
      );
      final receiptCart = List<_CartLine>.from(_cart);
      final subtotal = _subtotal;
      final discount = _discountPercent;
      final user = await ApiService.getUser();
      if (!mounted) return;
      setState(() {
        _success = 'Sale #${data['id']} completed — Rs ${data['totalAmount']}';
        _cart = [];
        _customerController.clear();
        _discountController.clear();
      });
      await _load();
      if (!mounted) return;
      _showReceipt(data, receiptCart, subtotal, discount, user['shopName'] ?? 'Pharmacy');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not complete the sale.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showReceipt(Map<String, dynamic> sale, List<_CartLine> items, double subtotal, double discountPercent, String shopName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Receipt — Sale #${sale['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              if ((sale['customerName'] ?? '').toString().isNotEmpty)
                Text('Customer: ${sale['customerName']}', style: const TextStyle(color: AppColors.inkSoft)),
              const SizedBox(height: 12),
              ...items.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.medicineName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${c.quantity} units · Batch ${c.batchNumber}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('Rs ${(c.quantity * c.salePrice).toStringAsFixed(2)}'),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              _summaryRow('Subtotal', 'Rs ${(sale['subtotalAmount'] ?? subtotal)}'),
              if (((sale['discountPercent'] as num?)?.toDouble() ?? discountPercent) > 0)
                _summaryRow(
                  'Discount (${sale['discountPercent'] ?? discountPercent}%)',
                  '− Rs ${(subtotal - (sale['totalAmount'] as num).toDouble()).toStringAsFixed(2)}',
                  color: AppColors.good,
                ),
              _summaryRow('Total', 'Rs ${sale['totalAmount']}', bold: true),
              const SizedBox(height: 8),
              Text(shopName, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color ?? AppColors.ink)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? AppColors.ink)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picked = _pickedBatch;
    final pickedPackSize = picked != null ? _packSizeFor(picked['medicine']?['id']) : 1;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text('Add item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (_batches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No stock available to sell — add a batch first.', style: TextStyle(color: AppColors.inkSoft)),
          )
        else ...[
          DropdownButtonFormField<int>(
            value: _pickBatchId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Batch'),
            items: _batches.map<DropdownMenuItem<int>>((b) {
              final name = _medicineName(b['medicine']?['id']);
              return DropdownMenuItem(
                value: b['id'] as int,
                child: Text('$name — ${b['batchNumber']} (${b['quantity']} left, Rs ${b['salePrice']}/unit)', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) => setState(() {
              _pickBatchId = v;
              _pickMode = 'units';
            }),
          ),
          if (picked != null && pickedPackSize > 1) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Sell loose'),
                    selected: _pickMode == 'units',
                    onSelected: (_) => setState(() => _pickMode = 'units'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Whole pack (×$pickedPackSize)'),
                    selected: _pickMode == 'packs',
                    onSelected: (_) => setState(() => _pickMode = 'packs'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _pickMode == 'packs' ? 'Number of packs' : 'Quantity (units)',
              helperText: (picked != null && _pickMode == 'packs')
                  ? '= ${(int.tryParse(_qtyController.text) ?? 0) * pickedPackSize} tablets total'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _pickBatchId == null ? null : _addToCart,
              child: const Text('Add to cart'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text('Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_error!, style: const TextStyle(color: AppColors.bad, fontWeight: FontWeight.w600)),
          ),
        if (_success != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_success!, style: const TextStyle(color: AppColors.good, fontWeight: FontWeight.w600)),
          ),
        if (_cart.isEmpty)
          const Text('Cart is empty.', style: TextStyle(color: AppColors.inkSoft))
        else
          ..._cart.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
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
                          Text(c.medicineName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('Batch ${c.batchNumber} · ${c.quantity} units', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('Rs ${(c.quantity * c.salePrice).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: () => setState(() => _cart.removeWhere((x) => x.batchId == c.batchId)),
                      icon: const Icon(Icons.close, color: AppColors.bad),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 12),
        TextField(
          controller: _customerController,
          decoration: const InputDecoration(labelText: 'Customer name (optional)', hintText: 'Walk-in customer'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _discountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Discount (%)',
            hintText: '0',
            helperText: 'Optional — applied to the whole cart',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _summaryRow('Subtotal', 'Rs ${_subtotal.toStringAsFixed(2)}'),
        if (_discountPercent > 0)
          _summaryRow('Discount (${_discountPercent}%)', '− Rs ${_discountAmount.toStringAsFixed(2)}', color: AppColors.good),
        _summaryRow('Total', 'Rs ${_total.toStringAsFixed(2)}', bold: true),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving || _cart.isEmpty ? null : _completeSale,
            child: Text(_saving ? 'Processing…' : 'Complete sale'),
          ),
        ),
      ],
    );
  }
}

class _CartLine {
  final int batchId;
  final dynamic medicineId;
  final String medicineName;
  final String batchNumber;
  final int quantity;
  final double salePrice;

  _CartLine({
    required this.batchId,
    required this.medicineId,
    required this.medicineName,
    required this.batchNumber,
    required this.quantity,
    required this.salePrice,
  });

  _CartLine copyWith({int? quantity}) {
    return _CartLine(
      batchId: batchId,
      medicineId: medicineId,
      medicineName: medicineName,
      batchNumber: batchNumber,
      quantity: quantity ?? this.quantity,
      salePrice: salePrice,
    );
  }
}
