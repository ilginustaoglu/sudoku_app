import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../services/statistics_manager.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticsManager _statisticsManager = StatisticsManager();
  int _yearlyCompleted = 0;
  int _monthlyCompleted = 0;
  int _weeklyCompleted = 0;
  List<int> _weeklyDailyCompleted = [0, 0, 0, 0, 0, 0, 0];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final now = DateTime.now();
    final yearly = await _statisticsManager.getYearlyCompleted(now);
    final monthly = await _statisticsManager.getMonthlyCompleted(now);
    final weekly = await _statisticsManager.getWeeklyCompleted(now);
    final weeklyDaily = await _statisticsManager.getWeeklyDailyCompleted(now);

    setState(() {
      _yearlyCompleted = yearly;
      _monthlyCompleted = monthly;
      _weeklyCompleted = weekly;
      _weeklyDailyCompleted = weeklyDaily;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statistics),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İstatistik kartları
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          l10n.statYearly,
                          _yearlyCompleted.toString(),
                          Icons.calendar_today,
                          const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          l10n.statMonthly,
                          _monthlyCompleted.toString(),
                          Icons.calendar_month,
                          const Color(0xFF6F4E37),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          l10n.statWeekly,
                          _weeklyCompleted.toString(),
                          Icons.date_range,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Haftalık grafik
                  Text(
                    l10n.weeklyCompletedGames,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F4E37),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final days = l10n.weekdayShortLabels;
                                if (value.toInt() >= 0 && value.toInt() < 7) {
                                  return Text(
                                    days[value.toInt()],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: _getMaxYValue(),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _weeklyDailyCompleted.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                            }).toList(),
                            isCurved: true,
                            color: const Color(0xFF2E7D32),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxYValue() {
    final max = _weeklyDailyCompleted.reduce((a, b) => a > b ? a : b);
    return (max + 1).toDouble();
  }
}

