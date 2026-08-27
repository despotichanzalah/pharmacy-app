import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime.now();
  Map<String, dynamic>? _profit;
  List<dynamic> _topMedicines = [];
  bool _loading = true;
  String? _error;

  String get _monthKey => '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
  String get _monthLabel => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][_month.month] + ' ${_month.year}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getProfitReport(_monthKey),
        ApiService.getTopMedicines(_monthKey, limit: 10),
      ]);
      setState(() {
        _profit = results[0] as Map<String, dynamic>;
        _topMedicines = results[1] as List<dynamic>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = double.tryParse('${_profit?['netProfit'] ?? 0}') ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                Text(_monthLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(13),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: const Color(0xFFFDEAEA), borderRadius: BorderRadius.circular(10)),
                          child: Text(_error!, style: const TextStyle(color: AppColors.bad)),
                        ),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _statCard('Total Sales', 'Rs ${_profit?['totalSales'] ?? 0}', AppColors.primary),
                          _statCard('Total Cost', 'Rs ${_profit?['totalCost'] ?? 0}', AppColors.inkSoft),
                          _statCard('Refunds', 'Rs ${_profit?['totalRefunds'] ?? 0}', const Color(0xFFB8792E)),
                          _statCard('Net Profit', 'Rs ${_profit?['netProfit'] ?? 0}', netProfit < 0 ? AppColors.bad : AppColors.good),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Top-selling medicines', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            if (_topMedicines.isEmpty)
                              const Text('No sales recorded this month.', style: TextStyle(color: AppColors.inkSoft))
                            else
                              ..._topMedicines.asMap().entries.map((entry) {
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
                                        child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: AppColors.surface, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
