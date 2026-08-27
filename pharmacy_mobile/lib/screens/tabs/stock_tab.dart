import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class StockTab extends StatefulWidget {
  const StockTab({super.key});

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> {
  String _tab = 'all'; // all | low | expiring
  List<dynamic> _batches = [];
  List<dynamic> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ApiService.getMedicines().then((m) => setState(() => _medicines = m));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<dynamic> data;
      if (_tab == 'low') {
        data = await ApiService.getLowStockBatches(threshold: 10);
      } else if (_tab == 'expiring') {
        data = await ApiService.getExpiringBatches(days: 30);
      } else {
        data = await ApiService.getAllBatches();
      }
      setState(() => _batches = data);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  // Called by DashboardScreen every time this tab becomes visible, so a
  // newly added medicine's pack size etc. is never stale here.
  void reload() {
    ApiService.getMedicines().then((m) => setState(() => _medicines = m));
    _load();
  }

  String _medicineName(dynamic medicineId) {
    final m = _medicines.firstWhere((m) => m['id'] == medicineId, orElse: () => null);
    return m != null ? m['name'] : '#$medicineId';
  }

  int _packSizeFor(dynamic medicineId) {
    final m = _medicines.firstWhere((m) => m['id'] == medicineId, orElse: () => null);
    return m != null ? (m['packSize'] ?? 1) : 1;
  }

  void _openBatchSheet({Map<String, dynamic>? editing}) {
    final isEditing = editing != null;
    int? selectedMedicineId = editing != null ? editing['medicine']['id'] : null;
    final batchNumberController = TextEditingController(text: editing?['batchNumber'] ?? '');
    final quantityController = TextEditingController(text: editing != null ? '${editing['quantity']}' : '');
    final packsController = TextEditingController();
    final purchasePriceController = TextEditingController(text: editing != null ? '${editing['purchasePrice']}' : '');
    final salePriceController = TextEditingController(text: editing != null ? '${editing['salePrice']}' : '');
    final packPurchasePriceController = TextEditingController();
    final packSalePriceController = TextEditingController();
    DateTime? expiryDate = editing != null ? DateTime.tryParse(editing['expiryDate'] ?? '') : null;

    String entryMode = 'units'; // units | packs
    String priceMode = 'perUnit'; // perUnit | perPack
    bool saving = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final packSize = selectedMedicineId != null ? _packSizeFor(selectedMedicineId) : 1;

            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'Edit batch' : 'New batch', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    if (error != null)
                      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: AppColors.bad))),

                    if (!isEditing) ...[
                      DropdownButtonFormField<int>(
                        value: selectedMedicineId,
                        decoration: const InputDecoration(labelText: 'Medicine'),
                        items: _medicines.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']))).toList(),
                        onChanged: (v) => setSheetState(() => selectedMedicineId = v),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(controller: batchNumberController, decoration: const InputDecoration(labelText: 'Batch number')),
                    const SizedBox(height: 12),

                    if (!isEditing && packSize > 1) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Loose units'),
                              selected: entryMode == 'units',
                              onSelected: (_) => setSheetState(() => entryMode = 'units'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: Text('Packs (×$packSize)'),
                              selected: entryMode == 'packs',
                              onSelected: (_) => setSheetState(() => entryMode = 'packs'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!isEditing && entryMode == 'packs' && packSize > 1) ...[
                      TextField(
                        controller: packsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Number of packs', helperText: '= ${(int.tryParse(packsController.text) ?? 0) * packSize} total units'),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ] else ...[
                      TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity (units)')),
                    ],
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setSheetState(() => expiryDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Expiry date'),
                        child: Text(expiryDate != null ? '${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}' : 'Select date'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!isEditing && packSize > 1) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Price per unit'),
                              selected: priceMode == 'perUnit',
                              onSelected: (_) => setSheetState(() => priceMode = 'perUnit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Price per pack'),
                              selected: priceMode == 'perPack',
                              onSelected: (_) => setSheetState(() => priceMode = 'perPack'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!isEditing && priceMode == 'perPack' && packSize > 1) ...[
                      TextField(
                        controller: packPurchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Purchase price (per pack)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: packSalePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Sale price (per pack)'),
                      ),
                    ] else ...[
                      TextField(
                        controller: purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Purchase price (per unit)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: salePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Sale price (per unit)'),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!isEditing && selectedMedicineId == null) {
                                  setSheetState(() => error = 'Select a medicine.');
                                  return;
                                }
                                if (expiryDate == null) {
                                  setSheetState(() => error = 'Select an expiry date.');
                                  return;
                                }
                                setSheetState(() {
                                  saving = true;
                                  error = null;
                                });

                                final finalQty = (!isEditing && entryMode == 'packs')
                                    ? (int.tryParse(packsController.text) ?? 0) * packSize
                                    : (int.tryParse(quantityController.text) ?? 0);
                                final finalPurchase = (!isEditing && priceMode == 'perPack')
                                    ? (double.tryParse(packPurchasePriceController.text) ?? 0) / packSize
                                    : (double.tryParse(purchasePriceController.text) ?? 0);
                                final finalSale = (!isEditing && priceMode == 'perPack')
                                    ? (double.tryParse(packSalePriceController.text) ?? 0) / packSize
                                    : (double.tryParse(salePriceController.text) ?? 0);
                                final expiryStr = '${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}';

                                try {
                                  if (isEditing) {
                                    await ApiService.updateBatch(
                                      editing['id'],
                                      batchNumber: batchNumberController.text.trim(),
                                      quantity: finalQty,
                                      expiryDate: expiryStr,
                                      purchasePrice: finalPurchase,
                                      salePrice: finalSale,
                                    );
                                  } else {
                                    await ApiService.addBatch(
                                      medicineId: selectedMedicineId!,
                                      batchNumber: batchNumberController.text.trim(),
                                      quantity: finalQty,
                                      expiryDate: expiryStr,
                                      purchasePrice: finalPurchase,
                                      salePrice: finalSale,
                                    );
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _load();
                                } catch (e) {
                                  setSheetState(() {
                                    error = e.toString();
                                    saving = false;
                                  });
                                }
                              },
                        child: Text(saving ? 'Saving…' : (isEditing ? 'Save changes' : 'Save batch')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete batch?'),
        content: Text('Delete batch ${batch['batchNumber']}? This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.bad))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteBatch(batch['id']);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _openBatchSheet(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _tabChip('all', 'All stock')),
                const SizedBox(width: 8),
                Expanded(child: _tabChip('low', 'Low stock')),
                const SizedBox(width: 8),
                Expanded(child: _tabChip('expiring', 'Expiring')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _batches.isEmpty
                    ? const Center(child: Text('No batches here.', style: TextStyle(color: AppColors.inkSoft)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _batches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final b = _batches[i];
                          final lowQty = (b['quantity'] ?? 0) <= 10;
                          return Container(
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
                                      Text(_medicineName(b['medicine']?['id']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      const SizedBox(height: 3),
                                      Text('Batch ${b['batchNumber']} · Exp ${b['expiryDate']}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                                      const SizedBox(height: 3),
                                      Text('Rs ${b['purchasePrice']} → Rs ${b['salePrice']}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: lowQty ? const Color(0xFFFFF3E0) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('${b['quantity']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: lowQty ? const Color(0xFFB8792E) : AppColors.ink)),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: AppColors.inkSoft),
                                  onSelected: (v) {
                                    if (v == 'edit') _openBatchSheet(editing: b);
                                    if (v == 'delete') _confirmDelete(b);
                                  },
                                  itemBuilder: (ctx) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.bad))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String value, String label) {
    final active = _tab == value;
    return GestureDetector(
      onTap: () {
        setState(() => _tab = value);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : AppColors.line),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}
