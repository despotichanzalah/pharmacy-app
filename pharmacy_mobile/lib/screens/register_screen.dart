import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../i18n/app_lang.dart';
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
  bool _obscurePassword = true;
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
    return AnimatedBuilder(
      animation: AppLang.instance,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(t('createYourAccount'))),
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
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 14))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t('createYourAccount'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                      const SizedBox(height: 8),
                      Text(t('createAccountSub'), style: const TextStyle(color: AppColors.inkSoft, fontSize: 14)),
                      const SizedBox(height: 22),

                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEAEA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF3B4AE)),
                          ),
                          child: Text(_error!, style: const TextStyle(color: AppColors.bad, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),

                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(child: _modeButton('create', t('startNewShop'))),
                            Expanded(child: _modeButton('join', t('joinMyShop'))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      Text(t('yourName'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Huny', prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.inkSoft)),
                      ),
                      const SizedBox(height: 16),

                      Text(t('email'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'you@shop.com', prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.inkSoft)),
                      ),
                      const SizedBox(height: 16),

                      Text(t('password'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.inkSoft),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.inkSoft),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_mode == 'create') ...[
                        Text(t('shopName'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _shopNameController,
                          decoration: const InputDecoration(hintText: 'Huny Pharmacy', prefixIcon: Icon(Icons.storefront_outlined, size: 20, color: AppColors.inkSoft)),
                        ),
                        const SizedBox(height: 6),
                        Text(t('youWillBeAdmin'), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                      ] else ...[
                        Text(t('yourShop'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedShopId,
                          items: _shops
                              .map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'])))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedShopId = v),
                          decoration: InputDecoration(hintText: t('selectShop'), prefixIcon: const Icon(Icons.storefront_outlined, size: 20, color: AppColors.inkSoft)),
                        ),
                        const SizedBox(height: 16),
                        Text(t('yourRole'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _roleName,
                          items: [
                            DropdownMenuItem(value: 'PHARMACIST', child: Text(t('pharmacist'))),
                            DropdownMenuItem(value: 'CASHIER', child: Text(t('cashier'))),
                            DropdownMenuItem(value: 'ADMIN', child: Text(t('admin'))),
                          ],
                          onChanged: (v) => setState(() => _roleName = v ?? 'CASHIER'),
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppColors.inkSoft)),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(elevation: 6, shadowColor: AppColors.primary.withOpacity(0.4)),
                          onPressed: _loading ? null : _handleSubmit,
                          child: Text(_loading ? t('creatingAccount') : t('createAccount'), style: const TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: active ? AppColors.primaryDark : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
