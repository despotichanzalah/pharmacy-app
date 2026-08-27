import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class _PurchaseCartLine {
  final Map<String, dynamic> medicine;
  final String batchNumber;
  final int quantity;
  final double unitPrice;
  final DateTime expiryDate;
  _PurchaseCartLine({
    required this.medicine,
    required this.batchNumber,
    required this.quantity,
    required this.unitPrice,
    required this.expiryDate,
  });

  double get lineTotal => quantity * unitPrice;
}

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<dynamic> _purchases = [];
  List<dynamic> _suppliers = [];
  List<dynamic> _medicines = [];
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
        ApiService.listPurchases(),
        ApiService.getSuppliers(),
        ApiService.getMedicines(),
      ]);
      setState(() {
        _purchases = results[0];
        _suppliers = results[1];
        _medicines = results[2];
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  String _supplierName(dynamic id) {
    final s = _suppliers.firstWhere((s) => s['id'] == id, orElse: () => null);
    return s != null ? s['name'] : '—';
  }

  String _medicineName(dynamic id) {
    final m = _medicines.firstWhere((m) => m['id'] == id, orElse: () => null);
    return m != null ? m['name'] : '—';
  }

  void _openItemsSheet(Map<String, dynamic> purchase) async {
    List<dynamic> items = [];
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          if (loading) {
            ApiService.getPurchaseItems(purchase['id']).then((data) {
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
                Text('Purchase #${purchase['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                if (loading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else
                  ...items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_medicineName(it['medicine']?['id']), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text('Batch ${it['batchNumber']} · Exp ${it['expiryDate']}', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                                ],
                              ),
                            ),
                            Text('${it['quantity']} × Rs ${it['unitPrice']}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      )),
              ],
            ),
          );
        });
      },
    );
  }

  void _openNewPurchaseSheet() {
    int? selectedSupplierId;
    final List<_PurchaseCartLine> cart = [];
    bool saving = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          void addItem() {
            int? medicineId;
            final batchController = TextEditingController();
            final qtyController = TextEditingController();
            final priceController = TextEditingController();
            DateTime? expiry;

            showModalBottomSheet(
              context: ctx,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (ctx2) {
                return StatefulBuilder(builder: (ctx2, setItemState) {
                  return Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: medicineId,
                          decoration: const InputDecoration(labelText: 'Medicine'),
                          items: _medicines.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']))).toList(),
                          onChanged: (v) => setItemState(() => medicineId = v),
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: batchController, decoration: const InputDecoration(labelText: 'Batch number')),
                        const SizedBox(height: 12),
                        TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
                        const SizedBox(height: 12),
                        TextField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Unit price (purchase cost)')),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx2,
                              initialDate: DateTime.now().add(const Duration(days: 180)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setItemState(() => expiry = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Expiry date'),
                            child: Text(expiry != null ? '${expiry!.year}-${expiry!.month.toString().padLeft(2, '0')}-${expiry!.day.toString().padLeft(2, '0')}' : 'Select date'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (medicineId == null || expiry == null || batchController.text.trim().isEmpty) return;
                              final medicine = _medicines.firstWhere((m) => m['id'] == medicineId);
                              setSheetState(() {
                                cart.add(_PurchaseCartLine(
                                  medicine: medicine,
                                  batchNumber: batchController.text.trim(),
                                  quantity: int.tryParse(qtyController.text) ?? 0,
                                  unitPrice: double.tryParse(priceController.text) ?? 0,
                                  expiryDate: expiry!,
                                ));
                              });
                              Navigator.pop(ctx2);
                            },
                            child: const Text('Add to purchase'),
                          ),
                        ),
                      ],
                    ),
                  );
                });
              },
            );
          }

          final total = cart.fold<double>(0, (sum, c) => sum + c.lineTotal);

          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New purchase', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  if (error != null)
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: AppColors.bad))),
                  DropdownButtonFormField<int>(
                    value: selectedSupplierId,
                    decoration: const InputDecoration(labelText: 'Supplier'),
                    items: _suppliers.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']))).toList(),
                    onChanged: (v) => setSheetState(() => selectedSupplierId = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items', style: TextStyle(fontWeight: FontWeight.w800)),
                      TextButton.icon(onPressed: addItem, icon: const Icon(Icons.add, size: 18), label: const Text('Add item')),
                    ],
                  ),
                  if (cart.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No items added yet.', style: TextStyle(color: AppColors.inkSoft)))
                  else
                    ...cart.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.medicine['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('${c.quantity} × Rs ${c.unitPrice}', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                                  ],
                                ),
                              ),
                              Text('Rs ${c.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              IconButton(icon: const Icon(Icons.close, size: 16, color: AppColors.bad), onPressed: () => setSheetState(() => cart.remove(c))),
                            ],
                          ),
                        )),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                      Text('Rs ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (selectedSupplierId == null || cart.isEmpty) {
                                setSheetState(() => error = 'Select a supplier and add at least one item.');
                                return;
                              }
                              setSheetState(() {
                                saving = true;
                                error = null;
                              });
                              try {
                                await ApiService.createPurchase(
                                  supplierId: selectedSupplierId!,
                                  items: cart.map((c) => {
                                        'medicineId': c.medicine['id'],
                                        'batchNumber': c.batchNumber,
                                        'quantity': c.quantity,
                                        'unitPrice': c.unitPrice,
                                        'expiryDate': '${c.expiryDate.year}-${c.expiryDate.month.toString().padLeft(2, '0')}-${c.expiryDate.day.toString().padLeft(2, '0')}',
                                      }).toList(),
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _load();
                              } catch (e) {
                                setSheetState(() {
                                  error = e.toString();
                                  saving = false;
                                });
                              }
                            },
                      child: Text(saving ? 'Saving…' : 'Save purchase'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      floatingActionButton: FloatingActionButton(onPressed: _openNewPurchaseSheet, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
              ? const Center(child: Text('No purchases recorded yet.', style: TextStyle(color: AppColors.inkSoft)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _purchases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final p = _purchases[i];
                      return InkWell(
                        onTap: () => _openItemsSheet(p),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_supplierName(p['supplier']?['id']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    const SizedBox(height: 3),
                                    Text(DateTime.parse(p['purchaseDate']).toLocal().toString().substring(0, 16), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('Rs ${p['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.w800)),
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
