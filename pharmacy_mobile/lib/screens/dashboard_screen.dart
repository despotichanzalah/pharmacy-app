import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'sales_history_screen.dart';
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

  final _titles = ['Overview', 'Medicines', 'Stock', 'Sales'];
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text((_user['name'] ?? '?').isNotEmpty ? _user['name']![0] : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_user['shopName'] ?? 'Your Shop', style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(_user['role'] ?? '', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _drawerItem(Icons.receipt_long, 'Sales History', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen()));
              }),
              _drawerItem(Icons.undo, 'Returns', () {}),
              _drawerItem(Icons.local_shipping, 'Suppliers', () {}),
              _drawerItem(Icons.shopping_bag, 'Purchases', () {}),
              _drawerItem(Icons.bar_chart, 'Reports', () {}),
              if (_user['role'] == 'ADMIN') _drawerItem(Icons.people, 'Staff', () {}),
              const Spacer(),
              const Divider(height: 1),
              _drawerItem(Icons.logout, 'Sign out', _logout, color: AppColors.bad),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          _reloadTab(i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.medication_outlined), selectedIcon: Icon(Icons.medication), label: 'Medicines'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.ink),
      title: Text(label, style: TextStyle(color: color ?? AppColors.ink, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
