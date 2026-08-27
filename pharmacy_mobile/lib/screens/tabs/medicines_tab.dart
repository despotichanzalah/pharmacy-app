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
      // keep old list on error, avoid a jarring empty state
    } finally {
      setState(() => _loading = false);
    }
  }

  // Called by DashboardScreen every time this tab becomes visible, so newly
  // added/edited medicines (e.g. pack size) are never stale.
  void reload() => _load(query: _query);

  void _openAddSheet({Map<String, dynamic>? editing}) {
    final isEditing = editing != null;
    final nameController = TextEditingController(text: editing?['name'] ?? '');
    final unitController = TextEditingController(text: editing?['unit'] ?? '');
    final reorderController = TextEditingController(text: '${editing?['reorderLevel'] ?? 10}');
    final packSizeController = TextEditingController(text: '${editing?['packSize'] ?? 1}');
    final genericInputController = TextEditingController();

    // Each item: {'id': int?, 'name': String, 'isNew': bool}
    final List<Map<String, dynamic>> selectedGenerics = editing != null
        ? ((editing['generics'] as List?) ?? []).map<Map<String, dynamic>>((g) => {'id': g['id'], 'name': g['name'], 'isNew': false}).toList()
        : [];
    List<dynamic> genericSuggestions = [];

    bool saving = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'Edit medicine' : 'New medicine', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(error!, style: const TextStyle(color: AppColors.bad)),
                      ),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Generic / formula', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Not in the list? Type it and tap Add — saved for next time.',
                        style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
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
                          children: genericSuggestions
                              .map<Widget>((g) => ListTile(
                                    dense: true,
                                    title: Text(g['name']),
                                    onTap: () => addGeneric(id: g['id'], name: g['name']),
                                  ))
                              .toList(),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
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
                                    await ApiService.addMedicine(
                                      name: nameController.text.trim(),
                                      unit: unitController.text.trim(),
                                      reorderLevel: int.tryParse(reorderController.text) ?? 10,
                                      packSize: int.tryParse(packSizeController.text) ?? 1,
                                      genericIds: selectedGenerics.where((g) => g['id'] != null).map<int>((g) => g['id'] as int).toList(),
                                      newGenerics: selectedGenerics.where((g) => g['isNew'] == true).map<String>((g) => g['name'] as String).toList(),
                                    );
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _load(query: _query);
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.bad)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteMedicine(medicine['id']);
      _load(query: _query);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _openAddSheet, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search medicines or generics…',
                prefixIcon: Icon(Icons.search),
              ),
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
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                            const SizedBox(height: 3),
                                            Text('${m['unit'] ?? '—'} · Reorder at ${m['reorderLevel']}',
                                                style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                                          ],
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
                                        children: generics
                                            .map<Widget>((g) => Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                                                  child: Text(g['name'], style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                                                ))
                                            .toList(),
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
