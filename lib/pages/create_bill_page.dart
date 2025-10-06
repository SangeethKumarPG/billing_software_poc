import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../db/db_helper.dart';
import '../models/bill.dart';
import '../models/service.dart';
import '../models/staff.dart';
import 'invoice_generator.dart';
import '../utils/thermal_printer.dart';

class CreateBillPage extends StatefulWidget {
  const CreateBillPage({super.key});

  @override
  State<CreateBillPage> createState() => _CreateBillPageState();
}

class _CreateBillPageState extends State<CreateBillPage> {
  List<Service> _services = [];
  List<BillItem> _items = [];
  List<Staff> _staff = [];
  Staff? _selectedStaff;

  final customerC = TextEditingController();
  final discountC = TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final s = await DBHelper.getServices();
    final st = await DBHelper.getStaff();
    setState(() {
      _services = s;
      _staff = st;
    });
  }

  void _addItem(Service s) {
    setState(() {
      _items.add(BillItem(
        serviceId: s.id!,
        serviceName: s.name,
        unitPrice: s.price,
        quantity: 1,
      ));
    });
  }

  double get subtotal =>
      _items.fold(0, (sum, i) => sum + i.unitPrice * i.quantity);

  double get discountPercent =>
      double.tryParse(discountC.text.trim())?.clamp(0, 100) ?? 0;

  double get total => subtotal - (subtotal * discountPercent / 100);

  Future<void> _handleOvertimeAndIncentives(Staff staff) async {
    final now = DateTime.now();
    final hour = now.hour;
    bool eligibleOvertime = false;

    if (staff.gender.toLowerCase() == "female" && hour >= 19) {
      eligibleOvertime = true;
    } else if (staff.gender.toLowerCase() == "male" && hour >= 20) {
      eligibleOvertime = true;
    }

    double incentiveToAdd = 0.0;
    final bills = await DBHelper.getBills();
    final nowMonth = DateTime.now().month;
    final nowYear = DateTime.now().year;

    final staffBills = bills.where((b) =>
        b.staffId == staff.id &&
        b.date.month == nowMonth &&
        b.date.year == nowYear);

    final monthlyTotal = staffBills.fold(0.0, (sum, b) => sum + b.total);

    if (monthlyTotal > 100000) {
      incentiveToAdd += staff.salary * 0.05;
    }

    bool hasBridalService = _items.any((item) =>
        item.serviceName.toLowerCase().contains("bridal"));

    if (hasBridalService) {
      incentiveToAdd += staff.salary * 0.10;
    }

    double overtimeToAdd = eligibleOvertime ? 60 : 0;

    if (incentiveToAdd > 0 || overtimeToAdd > 0) {
      final updated = Staff(
        id: staff.id,
        name: staff.name,
        salary: staff.salary,
        overtime: staff.overtime + overtimeToAdd,
        incentive: staff.incentive + incentiveToAdd,
        gender: staff.gender,
      );

      await DBHelper.updateStaff(updated);

      String message = "${staff.name} ";
      if (overtimeToAdd > 0) message += "earned ₹60 overtime. ";
      if (incentiveToAdd > 0) {
        message +=
            "received ₹${incentiveToAdd.toStringAsFixed(2)} incentive.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<Bill?> _saveBillToDb() async {
    if (_selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a staff")),
      );
      return null;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one service")),
      );
      return null;
    }

    await _handleOvertimeAndIncentives(_selectedStaff!);

    final bill = Bill(
      invoiceNo: const Uuid().v4().substring(0, 8).toUpperCase(),
      customerName: customerC.text.trim(),
      date: DateTime.now(),
      total: total,
      items: _items,
      staffId: _selectedStaff!.id,
      staffName: _selectedStaff!.name,
    );

    final id = await DBHelper.insertBill(bill);
    final savedBills = await DBHelper.getBills();
    return savedBills.firstWhere((b) => b.id == id);
  }

  Future<void> _saveAndPrintPdf() async {
    final saved = await _saveBillToDb();
    if (saved != null) {
      await InvoiceGenerator.printBill(saved);
      Navigator.pop(context);
    }
  }

  Future<void> _saveAndPrintThermal() async {
    final saved = await _saveBillToDb();
    if (saved != null) {
      await ThermalPrinterHelper.printCustomerCopy(saved);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Bill")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: customerC,
              decoration: const InputDecoration(labelText: "Customer Name"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Staff>(
              value: _selectedStaff,
              decoration: const InputDecoration(labelText: "Select Staff"),
              items: _staff
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text("${s.name} (${s.gender})"),
                      ))
                  .toList(),
              onChanged: (s) => setState(() => _selectedStaff = s),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountC,
              decoration: const InputDecoration(
                labelText: "Discount (%)",
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, i) {
                  final s = _services[i];
                  return GestureDetector(
                    onTap: () => _addItem(s),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: Colors.indigo.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "₹${s.price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                  color: Colors.indigo,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return ListTile(
                    title: Text(item.serviceName),
                    subtitle: Text(
                        "₹${item.unitPrice} x ${item.quantity} = ₹${(item.unitPrice * item.quantity).toStringAsFixed(2)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                item.quantity =
                                    (item.quantity > 1) ? item.quantity - 1 : 1;
                              });
                            }),
                        IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                item.quantity++;
                              });
                            }),
                      ],
                    ),
                  );
                },
              ),
            ),
            Column(
              children: [
                Text("Subtotal: ₹${subtotal.toStringAsFixed(2)}"),
                Text("Discount: ${discountPercent.toStringAsFixed(1)}%"),
                const SizedBox(height: 4),
                Text(
                  "Total: ₹${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveAndPrintPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Save & Print PDF"),
                ),
                ElevatedButton.icon(
                  onPressed: _saveAndPrintThermal,
                  icon: const Icon(Icons.print),
                  label: const Text("Thermal Copy"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
