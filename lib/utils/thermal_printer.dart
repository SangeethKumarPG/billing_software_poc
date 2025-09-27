import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import '../models/bill.dart';

class ThermalPrinterHelper {
  static Future<void> printCustomerCopy(Bill bill) async {
    // Correct usage
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm58, profile);

    final res = await printer.connect('192.168.0.123', port: 9100);

    if (res == PosPrintResult.success) {
      // Shop header
      printer.text(
        'MY SHOP NAME',
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      printer.text('123, Main Street, Kochi',
          styles: PosStyles(align: PosAlign.center));
      printer.text('Phone: +91 9876543210',
          styles: PosStyles(align: PosAlign.center));
      printer.text('-------------------------------');

      // Bill info
      printer.text('Invoice: ${bill.invoiceNo}');
      printer.text('Customer: ${bill.customerName}');
      printer.text('Date: ${bill.date}');
      printer.text('-------------------------------');

      // Items
      for (final item in bill.items) {
        printer.row([
          PosColumn(text: item.serviceName, width: 6),
          PosColumn(text: '${item.quantity}', width: 2),
          PosColumn(text: '₹${item.unitPrice}', width: 2),
          PosColumn(
            text: '₹${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
            width: 2,
          ),
        ]);
      }

      printer.text('-------------------------------');
      printer.text('TOTAL: ₹${bill.total.toStringAsFixed(2)}',
          styles: PosStyles(align: PosAlign.right, bold: true));

      printer.text('\nThank you! Visit again.',
          styles: PosStyles(align: PosAlign.center));

      printer.cut();
      printer.disconnect();
    }
  }
}
