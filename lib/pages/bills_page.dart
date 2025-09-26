import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/bill.dart';
import 'create_bill_page.dart';
import 'invoice_generator.dart';

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
      body: ListView.builder(
        itemCount: _bills.length,
        itemBuilder: (_, i) {
          final b = _bills[i];
          return ListTile(
            title: Text("Invoice: ${b.invoiceNo}"),
            subtitle: Text("${b.customerName} • ${b.date.toLocal()}"),
            trailing: IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => InvoiceGenerator.printBill(b),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CreateBillPage()));
          _loadBills();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
