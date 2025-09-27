import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/db_helper.dart';
import '../models/bill.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  double monthlySales = 0;
  Map<String, double> staffSales = {};
  Map<int, double> weeklySales = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final bills = await DBHelper.getBills();
    final now = DateTime.now();

    // Monthly sales
    final monthBills =
        bills.where((b) => b.date.month == now.month && b.date.year == now.year);
    final total = monthBills.fold(0.0, (sum, b) => sum + b.total);

    // Staff performance (Pie chart)
    final staffTotals = <String, double>{};
    for (final b in monthBills) {
      final staff = b.staffName ?? "Unknown";
      staffTotals[staff] = (staffTotals[staff] ?? 0) + b.total;
    }

    // Weekly sales (Line chart)
    final weekTotals = <int, double>{}; // weekday -> total
    for (final b in monthBills) {
      final weekday = b.date.weekday; // 1 = Mon, 7 = Sun
      weekTotals[weekday] = (weekTotals[weekday] ?? 0) + b.total;
    }

    setState(() {
      monthlySales = total;
      staffSales = staffTotals;
      weeklySales = weekTotals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Monthly Sales: ₹${monthlySales.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(toY: monthlySales, color: Colors.indigo)
                  ]),
                ],
                titlesData: FlTitlesData(show: true),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Pie Chart - Staff Performance
          Text("Staff Performance (This Month)",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: staffSales.entries
                    .map((e) => PieChartSectionData(
                          value: e.value,
                          title:
                              "${e.key}\n₹${e.value.toStringAsFixed(0)}",
                          color: Colors.primaries[
                              staffSales.keys.toList().indexOf(e.key) %
                                  Colors.primaries.length],
                          radius: 80,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Line Chart - Weekly Sales
          Text("Weekly Sales Trend",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklySales.entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
