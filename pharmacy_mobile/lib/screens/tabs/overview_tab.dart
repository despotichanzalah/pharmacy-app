import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ApiService.getUser();
      final isAdmin = user['role'] == 'ADMIN';
      if (mounted) setState(() => _user = user);

      final stockResults = await Future.wait([
        ApiService.getLowStockBatches(threshold: 10),
        ApiService.getExpiringBatches(days: 30),
        ApiService.getAllBatches(),
      ]);
      setState(() {
        _lowStock = stockResults[0];
        _expiring = stockResults[1];
        _allBatches = stockResults[2];
      });

      if (isAdmin) {
        try {
          final reportResults = await Future.wait([
            ApiService.getProfitReport(_currentMonth),
            ApiService.getDailySales(days: 7),
            ApiService.getTopMedicines(_currentMonth, limit: 5),
          ]);
          setState(() {
            _profit = reportResults[0] as Map<String, dynamic>;
            _dailySales = reportResults[1] as List<dynamic>;
            _topMedicines = reportResults[2] as List<dynamic>;
          });
        } catch (_) {}
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void reload() => _load();

  bool get _isAdmin => _user['role'] == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final problemIds = {..._lowStock.map((b) => b['id']), ..._expiring.map((b) => b['id'])};
    final healthyCount = _allBatches.where((b) => !problemIds.contains(b['id'])).length;
    final healthyPct = _allBatches.isNotEmpty ? (healthyCount / _allBatches.length * 100) : 100.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _welcomeHeader(),
          const SizedBox(height: 18),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(13),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFFDEAEA), borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: AppColors.bad)),
            ),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              if (_isAdmin) ...[
                _statCard(Icons.trending_up_rounded, 'Net Profit', _profit != null ? 'Rs ${_profit!['netProfit']}' : '—',
                    (double.tryParse('${_profit?['netProfit'] ?? 0}') ?? 0) < 0 ? AppColors.bad : AppColors.good),
                _statCard(Icons.payments_rounded, 'Total Sales', _profit != null ? 'Rs ${_profit!['totalSales']}' : '—', AppColors.primary),
              ],
              _statCard(Icons.inventory_2_rounded, 'Low Stock', '${_lowStock.length}', _lowStock.isEmpty ? AppColors.good : const Color(0xFFB8792E)),
              _statCard(Icons.event_busy_rounded, 'Expiring Soon', '${_expiring.length}', _expiring.isEmpty ? AppColors.good : AppColors.bad),
            ],
          ),
          const SizedBox(height: 18),

          if (_isAdmin) ...[
            _sectionTitle('Revenue trend', trailing: '7 days'),
            const SizedBox(height: 10),
            _panelCard(child: _revenueChart()),
            const SizedBox(height: 18),
          ],

          _sectionTitle('Stock health'),
          const SizedBox(height: 10),
          _panelCard(
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 3,
                          centerSpaceRadius: 32,
                          sections: [
                            PieChartSectionData(
                              value: healthyPct,
                              color: AppColors.good,
                              radius: 16,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: 100 - healthyPct,
                              color: AppColors.line,
                              radius: 16,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Text('${healthyPct.round()}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendRow(AppColors.good, 'Available', healthyCount),
                      const SizedBox(height: 8),
                      _legendRow(AppColors.line, 'Needs attention', _allBatches.length - healthyCount),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (_isAdmin) ...[
            _sectionTitle('Top-selling medicines'),
            const SizedBox(height: 10),
            _panelCard(
              child: _topMedicines.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No sales recorded yet this month.', style: TextStyle(color: AppColors.inkSoft)))
                  : Column(
                      children: _topMedicines.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final m = entry.value;
                        final maxQty = (_topMedicines.first['quantitySold'] as num).toDouble();
                        final pct = maxQty > 0 ? ((m['quantitySold'] as num).toDouble() / maxQty) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: rank == 1 ? AppColors.primary : AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text('$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: rank == 1 ? Colors.white : AppColors.inkSoft)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(m['medicineName'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                        Text('${m['quantitySold']} sold', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        backgroundColor: AppColors.surface,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 18),
          ],

          _sectionTitle('Expiring soon'),
          const SizedBox(height: 10),
          _panelCard(
            child: _expiring.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Nothing expiring in the next 30 days.', style: TextStyle(color: AppColors.inkSoft)))
                : Column(
                    children: _expiring.map<Widget>((b) => _alertRow('Batch ${b['batchNumber']}', 'Expires ${b['expiryDate']}')).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFEF9750)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${(_user['name'] ?? '').split(' ').firstOrNull ?? ''}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _user['shopName'] ?? "Here's how your shop looks today.",
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              ((_user['name'] ?? '?').isNotEmpty ? _user['name']![0] : '?').toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueChart() {
    if (_dailySales.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: Text('No sales yet this week.', style: TextStyle(color: AppColors.inkSoft))),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 1;
    for (var i = 0; i < _dailySales.length; i++) {
      final total = (_dailySales[i]['total'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), total));
      if (total > maxY) maxY = total;
    }
    maxY *= 1.25;

    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _dailySales.length) return const SizedBox.shrink();
                  final date = DateTime.tryParse(_dailySales[i]['date'] ?? '');
                  final label = date != null ? _weekdayShort(date.weekday) : '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                return LineTooltipItem('Rs ${s.y.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11));
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(radius: 3.5, color: AppColors.primary, strokeWidth: 2, strokeColor: Colors.white),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.28), AppColors.primary.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Text(trailing, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ),
      ],
    );
  }

  Widget _panelCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text('$label ($count)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _alertRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.bad.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.bad),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
