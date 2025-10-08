import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill.dart';

class InvoiceGenerator {
  static Future<Uint8List> generatePdf(Bill bill) async {
    final pdf = pw.Document();
    final df = DateFormat("dd-MM-yyyy HH:mm");

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("INVOICE", style: pw.TextStyle(fontSize: 24))),
          pw.Text("Invoice No: ${bill.invoiceNo}"),
          pw.Text("Date: ${df.format(bill.date)}"),
          pw.Text("Customer: ${bill.customerName}"),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ["Service", "Price", "Qty", "Total"],
            data: bill.items
                .map((i) => [
                      i.serviceName,
                      i.unitPrice.toStringAsFixed(2),
                      i.quantity.toString(),
                      (i.unitPrice * i.quantity).toStringAsFixed(2)
                    ])
                .toList(),
          ),
          pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text("Grand Total: Rs. ${bill.total.toStringAsFixed(2)}",
                style: pw.TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> printBill(Bill bill) async {
    final pdfData = await generatePdf(bill);
    await Printing.layoutPdf(onLayout: (_) => pdfData);
  }
}
