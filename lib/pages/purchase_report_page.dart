import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import 'package:intl/intl.dart';

class PurchaseReportPage extends StatefulWidget {
  const PurchaseReportPage({super.key});

  @override
  State<PurchaseReportPage> createState() => _PurchaseReportPageState();
}

class _PurchaseReportPageState extends State<PurchaseReportPage> {
  List<Map<String, dynamic>> _history = [];
  double totalPurchase = 0.0;
  double totalUsage = 0.0;

  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await DBHelper.getInventoryHistory();

    double purchaseSum = 0.0;
    double usageSum = 0.0;

    // Filter month-wise
    final filteredData = data.where((row) {
      final date = DateTime.parse(row["date"]);
      return date.month == selectedMonth && date.year == selectedYear;
    }).toList();

    for (var row in filteredData) {
      if (row["action"] == "purchase") {
        purchaseSum += (row["amount"] as num).toDouble();
      } else {
        usageSum += (row["amount"] as num).toDouble();
      }
    }

    setState(() {
      _history = filteredData;
      totalPurchase = purchaseSum;
      totalUsage = usageSum;
    });
  }

  // Helper to get month names
  List<String> get months => List.generate(12, (i) => DateFormat('MMMM').format(DateTime(0, i + 1)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Purchase & Usage Report")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMonth = value);
                      _loadHistory();
                    }
                  },
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(months[index]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: selectedYear,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedYear = value);
                      _loadHistory();
                    }
                  },
                  items: List.generate(
                    5,
                    (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(value: year, child: Text("$year"));
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Item Name")),
                  DataColumn(label: Text("Action")),
                  DataColumn(label: Text("Quantity")),
                  DataColumn(label: Text("Amount")),
                ],
                rows: _history.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(DateFormat("dd-MM-yyyy HH:mm")
                        .format(DateTime.parse(row["date"]).toLocal()))),
                    DataCell(Text(row["itemName"] ?? "")),
                    DataCell(Text(
                      row["action"] ?? "",
                      style: TextStyle(
                        color: (row["action"] == "purchase")
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    DataCell(Text(row["quantity"].toString())),
                    DataCell(Text("₹${(row["amount"] as num).toStringAsFixed(2)}")),
                  ]);
                }).toList(),
              ),
            ),
          ),

          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Total Purchase Amount: ₹${totalPurchase.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(
                  "Total Usage Amount: ₹${totalUsage.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
