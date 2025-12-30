import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'PaymentPage.dart';

Future<Uint8List> fetchImageBytes(String imageUrl) async {
  try {
    final response = await http.get(
      Uri.parse(imageUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0',
        // ❌ DO NOT set Accept-Encoding
      },
    );

    if (response.statusCode == 200 &&
        response.headers['content-type']?.startsWith('image/') == true) {
      return response.bodyBytes;
    }

    throw Exception('Invalid image response: ${response.statusCode}');
  } catch (e) {
    rethrow;
  }
}

Future<pw.Document> buildPdf({
  required String logo,
  required String hospitalName,
  required String hospitalPlace,
  required Map<String, dynamic> fee,
  required TextEditingController nameController,
  required TextEditingController cellController,
  required TextEditingController dobController,
}) async {
  final pdf = pw.Document();
  final blue = PdfColor.fromHex("#0A3D91");
  // final lightBlue = PdfColor.fromHex("#1E5CC4");

  // THERMAL PAGE FORMAT
  const double receiptWidth = 72 * PdfPageFormat.mm; // ~72mm

  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  // LOGO - Fixed version
  pw.Widget logoWidget = pw.SizedBox(width: 60, height: 60);
  if (logo.isNotEmpty) {
    try {
      final logoBytes = await fetchImageBytes(logo);
      final logoImage = pw.MemoryImage(logoBytes);
      logoWidget = pw.Center(
        child: pw.Image(
          logoImage,
          width: 60,
          height: 60,
          fit: pw.BoxFit.contain,
        ),
      );
    } catch (e) {
      // Fallback to placeholder text
      logoWidget = pw.Center(
        child: pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            color: blue,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text(
              'LOGO',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
      );
    }
  }

  pdf.addPage(
    pw.Page(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
      pageFormat: PdfPageFormat(
        receiptWidth,
        double.infinity,
        marginAll: 4 * PdfPageFormat.mm,
      ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // ---- Rounded Logo ----
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(width: 1, color: PdfColors.grey400),
                  ),
                  child: pw.ClipOval(
                    child: logoWidget, // pw.Image(...)
                  ),
                ),

                pw.SizedBox(width: 4),

                // ---- Hospital Info ----
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        hospitalName.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),

                      if (hospitalPlace.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          hospitalPlace,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // LOGO

            // HOSPITAL DETAILS
            pw.Divider(),

            // PATIENT INFO
            pw.Text(
              "PATIENT INFO",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "Name : ${nameController.text}",
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              "PID  : ${fee['Patient']['id']}",
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              "Phone: ${cellController.text}",
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              "Age  : ${FeesPaymentPageState.calculateAge(dobController.text)}",
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              "Sex  : ${fee['Patient']['gender']}",
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              "Date : ${FeesPaymentPageState.getFormattedDate(DateTime.now().toString())}",
              style: pw.TextStyle(fontSize: 9),
            ),

            pw.Divider(),

            // HEADLINE
            pw.Text(
              fee['reason'].toString().toUpperCase(),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 4),

            // TABLE HEADER
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    "SERVICE",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    "AMT",
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (fee['type'] == 'REGISTRATIONFEE') ...[
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: buildFeeRows(
                  registrationFee: fee['Consultation']?['registrationFee'],
                  consultationFee: fee['Consultation']?['consultationFee'],
                  emergencyFee: fee['Consultation']?['emergencyFee'],
                  sugarTestFee: fee['Consultation']?['sugarTestFee'],
                ),
              ),
            ],

            // TESTS LIST
            if (fee['TestingAndScanningPatients'] != null)
              ...fee['TestingAndScanningPatients'].map<pw.Widget>((t) {
                final String title = t['title']?.toString() ?? '-';
                final num testAmount = t['amount'] ?? 0;
                final dynamic selectedOption = t['selectedOptionAmounts'];

                final List<pw.Widget> rows = [];

                // 🔹 Parent test title (bold)
                rows.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            title,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              testAmount > 0 ? "₹ $testAmount" : "",
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                bool hasOptions = false;

                // 🔹 CASE 1: Map options
                if (selectedOption is Map) {
                  selectedOption.forEach((key, value) {
                    final num amt = num.tryParse(value.toString()) ?? 0;
                    if (amt > 0) {
                      hasOptions = true;
                      rows.add(
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10, top: 2),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  key.toString(),
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Align(
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    "₹ $amt",
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  });
                }
                // 🔹 CASE 2: List options
                else if (selectedOption is List) {
                  for (final o in selectedOption) {
                    if (o is Map) {
                      final String name = o['name']?.toString() ?? '';
                      final num amt = o['amount'] ?? 0;

                      if (name.isNotEmpty && amt > 0) {
                        hasOptions = true;
                        rows.add(
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10, top: 2),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    name,
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Text(
                                      "₹ $amt",
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                  }
                }

                // 🔹 CASE 3: No options → show total
                if (!hasOptions && testAmount > 0) {
                  rows.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, top: 2),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'Amount',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                "₹ $testAmount",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 🔹 Space after each test
                rows.add(pw.SizedBox(height: 6));

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: rows,
                );
              }).toList(),
            pw.Divider(),

            // TOTAL
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    "TOTAL",
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    "₹${FeesPaymentPageState.calculateTotal(fee['amount'])}",
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Text(
              "THANK YOU!",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
          ],
        );
      },
    ),
  );

  return pdf;
}

List<pw.TableRow> buildFeeRows({
  required num registrationFee,
  required num consultationFee,
  required num emergencyFee,
  required num sugarTestFee,
}) {
  final rows = <pw.TableRow>[];
  // 🔹 Section Header
  rows.add(
    pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 10, left: 8),
          child: pw.Text(
            "Bill Details",
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(),
      ],
    ),
  );

  void addRow(String title, num? amount) {
    if (amount == null || amount == 0) return;

    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey900),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "₹ ${amount.toStringAsFixed(0)}",
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Fee Rows
  addRow("Registration Fee", registrationFee);
  addRow("Consultation Fee", consultationFee);
  addRow("Emergency Fee", emergencyFee);
  addRow("Sugar Test Fee", sugarTestFee);

  return rows;
}
