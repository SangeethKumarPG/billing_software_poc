import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/db_helper.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  double monthlySales = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final bills = await DBHelper.getBills();
    final now = DateTime.now();
    final monthBills =
        bills.where((b) => b.date.month == now.month && b.date.year == now.year);
    final total = monthBills.fold(0.0, (sum, b) => sum + b.total);
    setState(() => monthlySales = total);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text("Monthly Sales: ₹${monthlySales.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
          ),
        ],
      ),
    );
  }
}
