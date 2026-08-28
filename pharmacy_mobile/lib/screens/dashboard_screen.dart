import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../i18n/app_lang.dart';
import 'login_screen.dart';
import 'sales_history_screen.dart';
import 'returns_screen.dart';
import 'suppliers_screen.dart';
import 'purchases_screen.dart';
import 'reports_screen.dart';
import 'staff_screen.dart';
import 'tabs/overview_tab.dart';
import 'tabs/medicines_tab.dart';
import 'tabs/stock_tab.dart';
import 'tabs/sales_tab.dart';

// The main app shell after login — bottom nav for the 4 most-used screens,
// drawer for everything else (mirrors the web sidebar).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;
  Map<String, String?> _user = {};

  List<String> get _titles => [t('overview'), t('medicines'), t('stock'), t('sales')];
  final _overviewKey = GlobalKey();
  final _medicinesKey = GlobalKey();
  final _stockKey = GlobalKey();
  final _salesKey = GlobalKey();

  void _reloadTab(int index) {
    final keys = [_overviewKey, _medicinesKey, _stockKey, _salesKey];
    // Dynamic call — each tab exposes its own reload(), avoiding needing to
    // name their (private) State classes here.
    (keys[index].currentState as dynamic)?.reload();
  }

  @override
  void initState() {
    super.initState();
    ApiService.getUser().then((u) => setState(() => _user = u));
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds this whole screen (title, drawer labels, nav labels) whenever the
    // language is toggled from the drawer, even though this screen is already mounted.
    return AnimatedBuilder(
      animation: AppLang.instance,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final tabs = [
      OverviewTab(key: _overviewKey),
      MedicinesTab(key: _medicinesKey),
      StockTab(key: _stockKey),
      SalesTab(key: _salesKey),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tabIndex]),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFEF9750)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        (_user['name'] ?? '?').isNotEmpty ? _user['name']![0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user['shopName'] ?? 'Your Shop',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              _user['role'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _drawerItem(Icons.receipt_long_rounded, t('salesHistory'), AppColors.primary, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen()));
                    }),
                    _drawerItem(Icons.undo_rounded, t('returns'), const Color(0xFFB8792E), () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReturnsScreen()));
                    }),
                    _drawerItem(Icons.local_shipping_rounded, t('suppliers'), const Color(0xFF6C8AE4), () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen()));
                    }),
                    _drawerItem(Icons.shopping_bag_rounded, t('purchases'), const Color(0xFF8B7FD6), () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
                    }),
                    if (_user['role'] == 'ADMIN')
                      _drawerItem(Icons.bar_chart_rounded, t('reports'), AppColors.good, () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                      }),
                    if (_user['role'] == 'ADMIN')
                      _drawerItem(Icons.people_rounded, t('staff'), const Color(0xFF4FB0C6), () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffScreen()));
                      }),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: _drawerItem(Icons.logout_rounded, t('signOut'), AppColors.bad, _logout),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _languageToggle(),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 14, top: 2),
                child: Text(
                  'PHARMACY SYSTEM · HUNY\'S APP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.inkSoft, letterSpacing: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          _reloadTab(i);
        },
        items: [
          _NavItem(icon: Icons.dashboard_rounded, label: t('overview')),
          _NavItem(icon: Icons.medication_rounded, label: t('medicines')),
          _NavItem(icon: Icons.inventory_2_rounded, label: t('stock')),
          _NavItem(icon: Icons.point_of_sale_rounded, label: t('sales')),
        ],
      ),
    );
  }

  Widget _languageToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: _langOption('English', !AppLang.instance.isUrdu)),
          Expanded(child: _langOption('اردو', AppLang.instance.isUrdu)),
        ],
      ),
    );
  }

  Widget _langOption(String label, bool active) {
    return GestureDetector(
      onTap: () {
        if (active) return;
        AppLang.instance.toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? AppColors.primaryDark : AppColors.inkSoft)),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, Color accent, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: TextStyle(color: accent == AppColors.bad ? AppColors.bad : AppColors.ink, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkSoft.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// A floating, rounded "pill" bottom nav bar with an animated active-tab
// highlight — replaces the default flat Material NavigationBar for a more
// premium, app-store-quality look.
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _FloatingNavBar({required this.selectedIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == selectedIndex;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: active ? 10 : 0),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 20, color: active ? Colors.white : AppColors.inkSoft),
                        if (active)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
