import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<dynamic> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getSuppliers();
      setState(() => _suppliers = data);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openAddSheet() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();
    bool saving = false;
    String? error;

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
                const Text('New supplier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                if (error != null)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: AppColors.bad))),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Supplier name')),
                const SizedBox(height: 12),
                TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact (phone/email)')),
                const SizedBox(height: 12),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
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
                              await ApiService.addSupplier(
                                name: nameController.text.trim(),
                                contact: contactController.text.trim(),
                                address: addressController.text.trim(),
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
                    child: Text(saving ? 'Saving…' : 'Save supplier'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      floatingActionButton: FloatingActionButton(onPressed: _openAddSheet, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? const Center(child: Text('No suppliers yet — tap + to add one.', style: TextStyle(color: AppColors.inkSoft)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _suppliers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final s = _suppliers[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            if ((s['contact'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(s['contact'], style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                            ],
                            if ((s['address'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(s['address'], style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
