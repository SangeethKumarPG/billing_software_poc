import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/staff.dart';
import '../models/bill.dart';
import '../utils/payslip_generator.dart'; 

class StaffSalaryReportPage extends StatefulWidget {
  const StaffSalaryReportPage({super.key});

  @override
  State<StaffSalaryReportPage> createState() => _StaffSalaryReportPageState();
}

class _StaffSalaryReportPageState extends State<StaffSalaryReportPage> {
  List<Staff> _staffList = [];
  List<Bill> _bills = [];
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final staff = await DBHelper.getStaff();
    final bills = await DBHelper.getBills();
    setState(() {
      _staffList = staff;
      _bills = bills;
      _loading = false;
    });
  }

  double _getStaffMonthlySales(int staffId) {
    final filteredBills = _bills.where((b) =>
        b.staffId == staffId &&
        b.date.month == selectedMonth &&
        b.date.year == selectedYear);
    return filteredBills.fold(0.0, (sum, b) => sum + b.total);
  }

  Future<void> _printPayslip(Staff staff) async {
    final monthlySales = _getStaffMonthlySales(staff.id ?? 0);
    final overtime = staff.overtime;
    final incentive = staff.incentive;
    final totalSalary = staff.salary + overtime + incentive;

    await PayslipGenerator.generatePayslip( 
      staffName: staff.name,
      gender: staff.gender,
      baseSalary: staff.salary,
      overtime: overtime,
      incentive: incentive,
      monthlySales: monthlySales,
      totalSalary: totalSalary,
      month: selectedMonth,
      year: selectedYear,
    );
  }

  List<DropdownMenuItem<int>> _buildMonthItems() {
    final months = List.generate(12, (i) => i + 1);
    return months
        .map((m) => DropdownMenuItem(
              value: m,
              child: Text(DateFormat.MMMM().format(DateTime(0, m))),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Staff Salary Report")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Text(
                        "Select Month:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: _buildMonthItems(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedMonth = val);
                        },
                      ),
                      const Spacer(),
                      const Icon(Icons.filter_alt, color: Colors.indigo),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.yMMMM()
                            .format(DateTime(selectedYear, selectedMonth)),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Staff Name")),
                        DataColumn(label: Text("Gender")),
                        DataColumn(label: Text("Monthly Sales")),
                        DataColumn(label: Text("Overtime (₹)")),
                        DataColumn(label: Text("Incentive (₹)")),
                        DataColumn(label: Text("Total Salary (₹)")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: _staffList.map((staff) {
                        final monthlySales =
                            _getStaffMonthlySales(staff.id ?? 0);
                        final overtime = staff.overtime;
                        final incentive = staff.incentive;
                        final totalSalary =
                            staff.salary + overtime + incentive;

                        return DataRow(cells: [
                          DataCell(Text(staff.name)),
                          DataCell(Text(staff.gender)),
                          DataCell(Text(monthlySales.toStringAsFixed(2))),
                          DataCell(Text(overtime.toStringAsFixed(2))),
                          DataCell(Text(incentive.toStringAsFixed(2))),
                          DataCell(Text(totalSalary.toStringAsFixed(2))),
                          DataCell(
                            ElevatedButton.icon(
                              onPressed: () => _printPayslip(staff),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text("Payslip"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
