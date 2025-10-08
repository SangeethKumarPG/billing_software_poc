import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PayslipGenerator {
  static Future<void> generatePayslip({
    required String staffName,
    required String gender,
    required double baseSalary,
    required double overtime,
    required double incentive,
    required double monthlySales,
    required double totalSalary,
    required int month,
    required int year,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormat.MMMM().format(DateTime(year, month));

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "PAYSLIP",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  "My Salon & Spa",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  "123, Main Street, Kochi | Ph: +91 9876543210",
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Employee Name: $staffName",
                  style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Gender: $gender",
                  style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Month: $monthName $year",
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text("Earnings Breakdown",
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _buildRow("Base Salary", baseSalary),
              _buildRow("Overtime", overtime),
              _buildRow("Incentive", incentive),
              _buildRow("Monthly Sales", monthlySales),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "TOTAL SALARY",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Rs.${totalSalary.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Center(
                child: pw.Text("Thank you for your contribution!",
                    style: const pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static pw.Widget _buildRow(String label, double value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text("Rs.${value.toStringAsFixed(2)}"),
      ],
    );
  }
}
