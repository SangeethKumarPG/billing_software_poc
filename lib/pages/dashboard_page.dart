import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/bill.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double todaySales = 0;
  double monthlySales = 0;
  int totalBills = 0;
  Map<String, double> staffPerformance = {}; 

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final bills = await DBHelper.getBills();
    final now = DateTime.now();

    // Today’s sales
    final today = bills.where((b) =>
        b.date.year == now.year &&
        b.date.month == now.month &&
        b.date.day == now.day);
    final todayTotal = today.fold(0.0, (sum, b) => sum + b.total);

    // This month’s sales
    final month = bills.where(
        (b) => b.date.year == now.year && b.date.month == now.month);
    final monthTotal = month.fold(0.0, (sum, b) => sum + b.total);

    final Map<String, double> staffTotals = {};
    for (final b in bills) {
      final name = b.staffName ?? "Unknown";
      staffTotals[name] = (staffTotals[name] ?? 0) + b.total;
    }

    setState(() {
      todaySales = todayTotal;
      monthlySales = monthTotal;
      totalBills = bills.length;
      staffPerformance = staffTotals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _buildStatCard("Today’s Sales", "₹${todaySales.toStringAsFixed(2)}", Icons.today),
              const SizedBox(width: 16),
              _buildStatCard("Monthly Sales", "₹${monthlySales.toStringAsFixed(2)}", Icons.calendar_month),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard("Total Bills", totalBills.toString(), Icons.receipt_long),

          const SizedBox(height: 24),
          const Text("Staff Performance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 12),
          ...staffPerformance.entries.map((e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.indigo),
                  title: Text(e.key),
                  trailing: Text("₹${e.value.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 36, color: Colors.indigo),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
