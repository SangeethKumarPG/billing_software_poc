import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../db/db_helper.dart';
import '../models/bill.dart';
import '../models/service.dart';
import '../models/staff.dart';
import 'invoice_generator.dart';
import '../utils/thermal_printer.dart'; // ✅ add this import

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

  double get total =>
      _items.fold(0, (sum, i) => sum + i.unitPrice * i.quantity);

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

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _services
                  .map((s) => ElevatedButton(
                        onPressed: () => _addItem(s),
                        child: Text(
                          "${s.name}\n₹${s.price.toStringAsFixed(0)}",
                          textAlign: TextAlign.center,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

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

            Text(
              "Total: ₹${total.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
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
