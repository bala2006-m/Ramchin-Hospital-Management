import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AccountsReportPdf {
  static Future<void> generate({
    required List<dynamic> payments,
    required double total,
    required String hospitalName,
    required String hospitalPlace,
    required String hospitalPhoto,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    // ---------- Load Logo ----------
    Uint8List? logo;
    try {
      final res = await http.get(Uri.parse(hospitalPhoto));
      if (res.statusCode == 200) logo = res.bodyBytes;
    } catch (_) {}

    // ---------- Group + Totals ----------
    double regTotal = 0;
    double testTotal = 0;
    Map<String, List<dynamic>> grouped = {};

    for (final p in payments) {
      final type = p['type'];
      final amount = double.parse(p['amount'].toString());

      grouped.putIfAbsent(type, () => []).add(p);

      if (type == 'REGISTRATIONFEE') regTotal += amount;
      if (type == 'TESTINGFEESANDSCANNINGFEE') testTotal += amount;
    }

    String typeLabel(String t) {
      if (t == 'REGISTRATIONFEE') return 'Registration Fee';
      if (t == 'TESTINGFEESANDSCANNINGFEE') return 'Test & Scan Fee';
      return t;
    }

    PdfColor typeColor(String t) {
      if (t == 'REGISTRATIONFEE') return PdfColors.blue;
      if (t == 'TESTINGFEESANDSCANNINGFEE') return PdfColors.green;
      return PdfColors.grey;
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // ---------- HEADER ----------
          pw.Row(
            children: [
              if (logo != null)
                pw.Container(
                  width: 55,
                  height: 55,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    image: pw.DecorationImage(
                      image: pw.MemoryImage(logo),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    hospitalName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(hospitalPlace, style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(),

          pw.Center(
            child: pw.Text(
              'ACCOUNTS REPORT',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 16),

          // ---------- SUMMARY ----------
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ---------- TITLE ----------
                pw.Text(
                  'SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                    letterSpacing: 1,
                  ),
                ),

                pw.SizedBox(height: 10),

                // ---------- REGISTRATION ----------
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Registration Fee',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      '₹ ${regTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 6),

                // ---------- TEST & SCAN ----------
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Test & Scan Fee',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      '₹ ${testTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.blue300),

                // ---------- GRAND TOTAL ----------
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GRAND TOTAL',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '₹ ${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ---------- TABLES (SAFE) ----------
          for (final entry in grouped.entries) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              color: typeColor(entry.key),
              child: pw.Text(
                typeLabel(entry.key),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.Table.fromTextArray(
              headers: ['Date', 'Patient ID', 'Payment ID', 'Amount'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey700),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
              },
              data: entry.value.map((p) {
                final date = DateFormat('dd MMM yyyy').format(p['createdAt']);
                final amount = double.parse(
                  p['amount'].toString(),
                ).toStringAsFixed(2);
                return [
                  date,
                  p['patient_Id'] ?? '-',
                  p['id'] ?? '-',
                  '₹ $amount',
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}
