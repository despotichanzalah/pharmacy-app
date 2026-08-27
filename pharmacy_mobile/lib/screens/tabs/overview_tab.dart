import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  Map<String, dynamic>? _profit;
  List<dynamic> _lowStock = [];
  List<dynamic> _expiring = [];
  List<dynamic> _allBatches = [];
  List<dynamic> _dailySales = [];
  List<dynamic> _topMedicines = [];
  Map<String, String?> _user = {};
  bool _loading = true;
  String? _error;

  String get _currentMonth {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    ApiService.getUser().then((u) => setState(() => _user = u));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getProfitReport(_currentMonth),
        ApiService.getLowStockBatches(threshold: 10),
        ApiService.getExpiringBatches(days: 30),
        ApiService.getAllBatches(),
        ApiService.getDailySales(days: 7),
        ApiService.getTopMedicines(_currentMonth, limit: 5),
      ]);
      setState(() {
        _profit = results[0] as Map<String, dynamic>;
        _lowStock = results[1] as List<dynamic>;
        _expiring = results[2] as List<dynamic>;
        _allBatches = results[3] as List<dynamic>;
        _dailySales = results[4] as List<dynamic>;
        _topMedicines = results[5] as List<dynamic>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Called by DashboardScreen every time this tab becomes visible.
  void reload() => _load();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final problemIds = {..._lowStock.map((b) => b['id']), ..._expiring.map((b) => b['id'])};
    final healthyCount = _allBatches.where((b) => !problemIds.contains(b['id'])).length;
    final healthyPct = _allBatches.isNotEmpty ? ((healthyCount / _allBatches.length) * 100).round() : 100;
    final maxDaily = _dailySales.fold<double>(1, (max, d) => (d['total'] as num).toDouble() > max ? (d['total'] as num).toDouble() : max);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back, ${(_user['name'] ?? '').split(' ').firstOrNull ?? ''}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text("Here's how your shop looks today.", style: TextStyle(color: AppColors.inkSoft)),
              ],
            ),
          ),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(13),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFFDEAEA), borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: const TextStyle(color: AppColors.bad)),
            ),

          // Stat cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _statCard('Net Profit', _profit != null ? 'Rs ${_profit!['netProfit']}' : '—',
                  (double.tryParse('${_profit?['netProfit'] ?? 0}') ?? 0) < 0 ? AppColors.bad : AppColors.good),
              _statCard('Total Sales', _profit != null ? 'Rs ${_profit!['totalSales']}' : '—', AppColors.primary),
              _statCard('Low Stock', '${_lowStock.length}', _lowStock.isEmpty ? AppColors.good : const Color(0xFFB8792E)),
              _statCard('Expiring Soon', '${_expiring.length}', _expiring.isEmpty ? AppColors.good : AppColors.bad),
            ],
          ),
          const SizedBox(height: 20),

          // Revenue trend
          _panelCard(
            title: 'Revenue trend (7 days)',
            child: _dailySales.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No sales yet this week.', style: TextStyle(color: AppColors.inkSoft)))
                : SizedBox(
                    height: 110,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _dailySales.map((d) {
                        final total = (d['total'] as num).toDouble();
                        final heightPct = maxDaily > 0 ? (total / maxDaily) : 0.0;
                        final date = DateTime.tryParse(d['date'] ?? '');
                        final label = date != null ? _weekdayShort(date.weekday) : '';
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 70 * (heightPct < 0.05 ? 0.05 : heightPct),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Stock health
          _panelCard(
            title: 'Stock health',
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: healthyPct / 100,
                          strokeWidth: 9,
                          backgroundColor: AppColors.line,
                          color: AppColors.good,
                        ),
                      ),
                      Text('$healthyPct%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendRow(AppColors.good, 'Available', healthyCount),
                      const SizedBox(height: 6),
                      _legendRow(AppColors.line, 'Monitor', _allBatches.length - healthyCount),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Top selling medicines
          _panelCard(
            title: 'Top-selling medicines',
            child: _topMedicines.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No sales recorded yet this month.', style: TextStyle(color: AppColors.inkSoft)))
                : Column(
                    children: _topMedicines.asMap().entries.map((entry) {
                      final m = entry.value;
                      final maxQty = (_topMedicines.first['quantitySold'] as num).toDouble();
                      final pct = maxQty > 0 ? ((m['quantitySold'] as num).toDouble() / maxQty) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(m['medicineName'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                Text('${m['quantitySold']} sold', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 7,
                                backgroundColor: AppColors.surface,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Expiring soon detail
          _panelCard(
            title: 'Expiring soon',
            child: _expiring.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nothing expiring in the next 30 days.', style: TextStyle(color: AppColors.inkSoft)))
                : Column(
                    children: _expiring.map<Widget>((b) => _alertRow('Expiring', 'Batch ${b['batchNumber']} — ${b['expiryDate']}', AppColors.bad)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _panelCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label ($count)', style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _alertRow(String badge, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(badge, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
