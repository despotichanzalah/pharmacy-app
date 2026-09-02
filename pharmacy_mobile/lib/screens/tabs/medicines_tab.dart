import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class MedicinesTab extends StatefulWidget {
  const MedicinesTab({super.key});

  @override
  State<MedicinesTab> createState() => _MedicinesTabState();
}

class _MedicinesTabState extends State<MedicinesTab> {
  List<dynamic> _medicines = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? query}) async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMedicines(query: query);
      setState(() => _medicines = data);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  void reload() => _load(query: _query);

  void _openHistory(Map<String, dynamic> medicine) {
    List<dynamic> batches = [];
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          if (loading) {
            ApiService.getBatchesForMedicine(medicine['id']).then((data) {
              setSheetState(() {
                batches = data;
                loading = false;
              });
            }).catchError((_) {
              setSheetState(() => loading = false);
            });
          }
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${medicine['name']} — batch history', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Every lot ever recorded, including depleted ones.', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                const SizedBox(height: 16),
                if (loading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (batches.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No batches recorded yet.', style: TextStyle(color: AppColors.inkSoft)))
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: batches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final b = batches[i];
                        final active = (b['quantity'] ?? 0) > 0;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: active ? Colors.white : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Batch ${b['batchNumber']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    Text('Exp ${b['expiryDate']} · Rs ${b['purchasePrice']} → Rs ${b['salePrice']}', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFFEAF7F0) : AppColors.line,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  active ? '${b['quantity']} left' : 'Depleted',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? AppColors.good : AppColors.inkSoft),
                                ),
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
        });
      },
    );
  }

  void _openAddSheet({Map<String, dynamic>? editing}) {
    final isEditing = editing != null;
    final nameController = TextEditingController(text: editing?['name'] ?? '');
    final unitController = TextEditingController(text: editing?['unit'] ?? '');
    final reorderController = TextEditingController(text: '${editing?['reorderLevel'] ?? 10}');
    final packSizeController = TextEditingController(text: '${editing?['packSize'] ?? 1}');
    final genericInputController = TextEditingController();

    final List<Map<String, dynamic>> selectedGenerics = editing != null
        ? ((editing['generics'] as List?) ?? []).map<Map<String, dynamic>>((g) => {'id': g['id'], 'name': g['name'], 'isNew': false}).toList()
        : [];
    List<dynamic> genericSuggestions = [];

    // Initial-stock fields — only used when creating a NEW medicine.
    final batchNumberController = TextEditingController();
    final quantityController = TextEditingController();
    final expiryController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final salePriceController = TextEditingController();
    final packsController = TextEditingController();
    final packPurchasePriceController = TextEditingController();
    final packSalePriceController = TextEditingController();
    DateTime? expiryDate;
    String entryMode = 'units';
    String priceMode = 'perUnit';

    bool saving = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final packSize = int.tryParse(packSizeController.text) ?? 1;

            Future<void> searchGenerics(String q) async {
              if (q.trim().isEmpty) {
                setSheetState(() => genericSuggestions = []);
                return;
              }
              try {
                final results = await ApiService.getGenerics(query: q);
                setSheetState(() => genericSuggestions = results);
              } catch (_) {}
            }

            void addGeneric({int? id, required String name}) {
              final already = selectedGenerics.any((g) => g['name'].toString().toLowerCase() == name.toLowerCase());
              if (already) return;
              setSheetState(() {
                selectedGenerics.add({'id': id, 'name': name, 'isNew': id == null});
                genericInputController.clear();
                genericSuggestions = [];
              });
            }

            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'Edit medicine' : 'New medicine', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    if (error != null)
                      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: AppColors.bad))),

                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Company / brand name')),
                    const SizedBox(height: 12),
                    TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (tablet, syrup…)')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: reorderController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Reorder level'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: packSizeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Pack size'),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Generic / formula', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: genericInputController,
                            decoration: const InputDecoration(hintText: 'e.g. Paracetamol'),
                            onChanged: searchGenerics,
                            onSubmitted: (v) {
                              if (v.trim().isNotEmpty) addGeneric(name: v.trim());
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final v = genericInputController.text.trim();
                            if (v.isNotEmpty) addGeneric(name: v);
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (genericSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: ListView(
                          shrinkWrap: true,
                          children: genericSuggestions.map<Widget>((g) => ListTile(dense: true, title: Text(g['name']), onTap: () => addGeneric(id: g['id'], name: g['name']))).toList(),
                        ),
                      ),
                    if (selectedGenerics.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedGenerics
                              .map((g) => Chip(
                                    label: Text(g['name']),
                                    backgroundColor: AppColors.primaryLight,
                                    labelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                                    deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryDark),
                                    onDeleted: () => setSheetState(() => selectedGenerics.remove(g)),
                                  ))
                              .toList(),
                        ),
                      ),

                    if (!isEditing) ...[
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 6),
                      const Text('Initial stock', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const Text('Every new medicine needs its first batch.', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                      const SizedBox(height: 12),

                      TextField(controller: batchNumberController, decoration: const InputDecoration(labelText: 'Batch number')),
                      const SizedBox(height: 12),

                      if (packSize > 1) ...[
                        Row(
                          children: [
                            Expanded(child: ChoiceChip(label: const Text('Loose units'), selected: entryMode == 'units', onSelected: (_) => setSheetState(() => entryMode = 'units'))),
                            const SizedBox(width: 8),
                            Expanded(child: ChoiceChip(label: Text('Packs (×$packSize)'), selected: entryMode == 'packs', onSelected: (_) => setSheetState(() => entryMode = 'packs'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (entryMode == 'packs' && packSize > 1)
                        TextField(
                          controller: packsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Number of packs', helperText: '= ${(int.tryParse(packsController.text) ?? 0) * packSize} total units'),
                          onChanged: (_) => setSheetState(() {}),
                        )
                      else
                        TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity (units)')),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 180)), firstDate: DateTime.now(), lastDate: DateTime(2100));
                          if (picked != null) {
                            expiryDate = picked;
                            expiryController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            setSheetState(() {});
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Expiry date'),
                          child: Text(expiryController.text.isEmpty ? 'Select date' : expiryController.text),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (packSize > 1) ...[
                        Row(
                          children: [
                            Expanded(child: ChoiceChip(label: const Text('Price per unit'), selected: priceMode == 'perUnit', onSelected: (_) => setSheetState(() => priceMode = 'perUnit'))),
                            const SizedBox(width: 8),
                            Expanded(child: ChoiceChip(label: const Text('Price per pack'), selected: priceMode == 'perPack', onSelected: (_) => setSheetState(() => priceMode = 'perPack'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (priceMode == 'perPack' && packSize > 1) ...[
                        TextField(controller: packPurchasePriceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Purchase price (per pack)')),
                        const SizedBox(height: 12),
                        TextField(controller: packSalePriceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sale price (per pack)')),
                      ] else ...[
                        TextField(controller: purchasePriceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Purchase price (per unit)')),
                        const SizedBox(height: 12),
                        TextField(controller: salePriceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sale price (per unit)')),
                      ],
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!isEditing && expiryDate == null) {
                                  setSheetState(() => error = 'Select an expiry date.');
                                  return;
                                }
                                setSheetState(() {
                                  saving = true;
                                  error = null;
                                });
                                try {
                                  if (isEditing) {
                                    await ApiService.updateMedicine(
                                      editing['id'],
                                      name: nameController.text.trim(),
                                      unit: unitController.text.trim(),
                                      reorderLevel: int.tryParse(reorderController.text) ?? 10,
                                      packSize: int.tryParse(packSizeController.text) ?? 1,
                                      genericIds: selectedGenerics.where((g) => g['id'] != null).map<int>((g) => g['id'] as int).toList(),
                                      newGenerics: selectedGenerics.where((g) => g['isNew'] == true).map<String>((g) => g['name'] as String).toList(),
                                    );
                                  } else {
                                    final newMedicine = await ApiService.addMedicine(
                                      name: nameController.text.trim(),
                                      unit: unitController.text.trim(),
                                      reorderLevel: int.tryParse(reorderController.text) ?? 10,
                                      packSize: packSize,
                                      genericIds: selectedGenerics.where((g) => g['id'] != null).map<int>((g) => g['id'] as int).toList(),
                                      newGenerics: selectedGenerics.where((g) => g['isNew'] == true).map<String>((g) => g['name'] as String).toList(),
                                    );

                                    final finalQty = entryMode == 'packs' ? (int.tryParse(packsController.text) ?? 0) * packSize : (int.tryParse(quantityController.text) ?? 0);
                                    final finalPurchase = priceMode == 'perPack' ? (double.tryParse(packPurchasePriceController.text) ?? 0) / packSize : (double.tryParse(purchasePriceController.text) ?? 0);
                                    final finalSale = priceMode == 'perPack' ? (double.tryParse(packSalePriceController.text) ?? 0) / packSize : (double.tryParse(salePriceController.text) ?? 0);

                                    await ApiService.addBatch(
                                      medicineId: newMedicine['id'],
                                      batchNumber: batchNumberController.text.trim(),
                                      quantity: finalQty,
                                      expiryDate: expiryController.text,
                                      purchasePrice: finalPurchase,
                                      salePrice: finalSale,
                                    );
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  reload();
                                } catch (e) {
                                  setSheetState(() {
                                    error = e.toString();
                                    saving = false;
                                  });
                                }
                              },
                        child: Text(saving ? 'Saving…' : (isEditing ? 'Save changes' : 'Save medicine')),
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

  Future<void> _confirmDelete(Map<String, dynamic> medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Delete "${medicine['name']}"? This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.bad))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteMedicine(medicine['id']);
      reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _openAddSheet(), child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Search medicines or generics…', prefixIcon: Icon(Icons.search)),
              onChanged: (v) {
                _query = v;
                _load(query: v);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _medicines.isEmpty
                      ? const Center(child: Text('No medicines yet — tap + to add one.', style: TextStyle(color: AppColors.inkSoft)))
                      : ListView.separated(
                          itemCount: _medicines.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final m = _medicines[i];
                            final generics = (m['generics'] as List?) ?? [];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _openHistory(m),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted)),
                                              const SizedBox(height: 3),
                                              Text('${m['unit'] ?? '—'} · Reorder at ${m['reorderLevel']}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if ((m['packSize'] ?? 1) > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                                          child: Text('×${m['packSize']}', style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w700)),
                                        ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: AppColors.inkSoft),
                                        onSelected: (v) {
                                          if (v == 'edit') _openAddSheet(editing: m);
                                          if (v == 'delete') _confirmDelete(m);
                                        },
                                        itemBuilder: (ctx) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.bad))),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (generics.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: generics.map<Widget>((g) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)), child: Text(g['name'], style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)))).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}