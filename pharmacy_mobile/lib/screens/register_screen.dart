import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _mode = 'create'; // 'create' | 'join'
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();

  List<dynamic> _shops = [];
  int? _selectedShopId;
  String _roleName = 'ADMIN';

  bool _loading = false;
  String? _error;

  void _switchMode(String mode) {
    setState(() {
      _mode = mode;
      _roleName = mode == 'create' ? 'ADMIN' : 'CASHIER';
    });
    if (mode == 'join') _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final shops = await ApiService.getShops();
      setState(() => _shops = shops);
    } catch (_) {
      setState(() => _shops = []);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        roleName: _roleName,
        shopName: _mode == 'create' ? _shopNameController.text.trim() : null,
        shopId: _mode == 'join' ? _selectedShopId : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Create your account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Open a new shop, or join one your team already runs.',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 15)),
                    const SizedBox(height: 20),

                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEAEA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF3B4AE)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.bad, fontWeight: FontWeight.w600)),
                      ),

                    // Mode switch: create vs join
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(child: _modeButton('create', 'Start a new shop')),
                          Expanded(child: _modeButton('join', 'Join my shop')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Your name', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Huny')),
                    const SizedBox(height: 16),

                    const Text('Email', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'you@shop.com'),
                    ),
                    const SizedBox(height: 16),

                    const Text('Password', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
                    const SizedBox(height: 16),

                    if (_mode == 'create') ...[
                      const Text('Shop name', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(controller: _shopNameController, decoration: const InputDecoration(hintText: 'Huny Pharmacy')),
                      const SizedBox(height: 6),
                      const Text("You'll be this shop's Admin.", style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                    ] else ...[
                      const Text('Your shop', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedShopId,
                        items: _shops
                            .map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'])))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedShopId = v),
                        decoration: const InputDecoration(hintText: 'Select a shop…'),
                      ),
                      const SizedBox(height: 16),
                      const Text('Your role', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _roleName,
                        items: const [
                          DropdownMenuItem(value: 'PHARMACIST', child: Text('Pharmacist')),
                          DropdownMenuItem(value: 'CASHIER', child: Text('Cashier')),
                          DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                        ],
                        onChanged: (v) => setState(() => _roleName = v ?? 'CASHIER'),
                      ),
                    ],

                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleSubmit,
                        child: Text(_loading ? 'Creating account…' : 'Create account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String value, String label) {
    final active = _mode == value;
    return GestureDetector(
      onTap: () => _switchMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: active ? AppColors.primaryDark : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
