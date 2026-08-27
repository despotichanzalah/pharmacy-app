import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<dynamic> _staff = [];
  String _myEmail = '';
  bool _loading = true;
  bool _deletingShop = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ApiService.getUser().then((u) => setState(() => _myEmail = u['email'] ?? ''));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.listStaff();
      setState(() => _staff = data);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmRemove(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove staff member?'),
        content: Text('Remove ${member['name']} from the shop? This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: AppColors.bad))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteStaff(member['id']);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _approve(Map<String, dynamic> member) async {
    try {
      await ApiService.approveStaff(member['id']);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmDeleteShop() async {
    final user = await ApiService.getUser();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delete this shop?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This permanently deletes "${user['shopName']}" and ALL its data — medicines, stock, sales, everything. This cannot be undone.'),
              const SizedBox(height: 16),
              const Text('Type DELETE to confirm.', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(controller: confirmController, onChanged: (_) => setDialogState(() {})),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: confirmController.text == 'DELETE' ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Delete', style: TextStyle(color: AppColors.bad)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _deletingShop = true);
    try {
      await ApiService.deleteMyShop();
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _deletingShop = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: _loading
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
                const Text('Team members', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                ..._staff.map((s) {
                  final isMe = s['email'] == _myEmail;
                  final isPending = s['approved'] == false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text((s['name'] ?? '?')[0], style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  if (isPending) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(20)),
                                      child: const Text('Pending', style: TextStyle(color: Color(0xFFB8792E), fontSize: 10, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ],
                              ),
                              Text('${s['role']?['name'] ?? ''} · ${s['email']}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (isPending)
                          TextButton(onPressed: () => _approve(s), child: const Text('Approve', style: TextStyle(color: AppColors.primaryDark))),
                        if (!isMe)
                          TextButton(onPressed: () => _confirmRemove(s), child: const Text('Remove', style: TextStyle(color: AppColors.bad))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.bad, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Danger zone', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.bad)),
                      const SizedBox(height: 8),
                      const Text(
                        'Permanently close this shop. All medicines, stock, sales, and staff accounts will be deleted.',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad, side: const BorderSide(color: AppColors.bad)),
                          onPressed: _deletingShop ? null : _confirmDeleteShop,
                          child: Text(_deletingShop ? 'Deleting…' : 'Delete this shop permanently'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
