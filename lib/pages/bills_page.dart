import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/bill.dart';
import 'create_bill_page.dart';
import 'invoice_generator.dart';
import '../utils/thermal_printer.dart'; // ✅ import thermal printer helper

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  List<Bill> _bills = [];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    final data = await DBHelper.getBills();
    setState(() => _bills = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bills.isEmpty
          ? const Center(child: Text("No bills available"))
          : ListView.builder(
              itemCount: _bills.length,
              itemBuilder: (_, i) {
                final b = _bills[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text("Invoice: ${b.invoiceNo}"),
                    subtitle: Text(
                        "${b.customerName} • ${b.date.toLocal().toString().split('.')[0]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Print PDF Invoice",
                          icon: const Icon(Icons.picture_as_pdf,
                              color: Colors.indigo),
                          onPressed: () => InvoiceGenerator.printBill(b),
                        ),
                        IconButton(
                          tooltip: "Print Thermal Copy",
                          icon: const Icon(Icons.print,
                              color: Colors.green),
                          onPressed: () =>
                              ThermalPrinterHelper.printCustomerCopy(b),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateBillPage()));
          _loadBills();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
