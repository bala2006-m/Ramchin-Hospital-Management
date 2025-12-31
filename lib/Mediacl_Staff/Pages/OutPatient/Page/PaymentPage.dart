import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Pages/payment_modal.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/payment_service.dart';
import '../../../../Services/socket_service.dart';
import '../../../../Services/testing&scanning_service.dart';
import '../../Medical/Widget/whatsApp_Send_PaymentBill.dart';
import 'widget.dart';

class FeesPaymentPage extends StatefulWidget {
  final Map<String, dynamic> fee;
  final Map<String, dynamic> patient;
  final int index;

  const FeesPaymentPage({
    super.key,
    required this.fee,
    required this.patient,
    required this.index,
  });

  @override
  State<FeesPaymentPage> createState() => FeesPaymentPageState();
}

class FeesPaymentPageState extends State<FeesPaymentPage> {
  final prefs = SharedPreferences.getInstance();
  bool _isProcessing = false;
  final socketService = SocketService();
  String? logo;
  String? hospitalName;
  String? hospitalPlace;
  bool _isLoading = false;
  bool _isBuildingPdf = false;

  late TextEditingController cellController;
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController dobController;
  late TextEditingController feeController;
  late TextEditingController idController;

  @override
  void initState() {
    super.initState();
    _updateTime();
    cellController = TextEditingController(
      text: extractString(widget.patient['phone'], 'mobile'),
    );
    nameController = TextEditingController(
      text: extractName(widget.patient['name']),
    );
    idController = TextEditingController(
      text: extractName(widget.patient['id']),
    );
    addressController = TextEditingController(
      text: extractString(widget.patient['address'], 'Address'),
    );
    dobController = TextEditingController(
      text: formatDob(extractString(widget.patient['dob'])),
    );
    feeController = TextEditingController(
      text: widget.fee['amount']?.toString() ?? '',
    );
    _loadHospitalLogo();
  }

  String? _dateTime;
  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  void _loadHospitalLogo() async {
    final prefs = await SharedPreferences.getInstance();

    logo = prefs.getString('hospitalPhoto');
    hospitalName = prefs.getString('hospitalName');
    hospitalPlace = prefs.getString('hospitalPlace');
    setState(() {});
  }

  String formatDob(String? dob) {
    if (dob == null || dob.trim().isEmpty) return 'N/A';

    try {
      // Try parsing "dd-MM-yyyy" format first
      DateTime date;
      if (dob.contains('-') && dob.split('-')[0].length == 2) {
        date = DateFormat('dd-MM-yyyy').parse(dob);
      } else {
        date = DateTime.parse(dob); // fallback for ISO format
      }

      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dob;
    }
  }

  static String calculateAge(String? dob) {
    if (dob == null || dob.trim().isEmpty) return 'N/A';

    try {
      DateTime birthDate;
      if (dob.contains('-') && dob.split('-')[0].length == 2) {
        // parse "02-11-2004"
        birthDate = DateFormat('dd-MM-yyyy').parse(dob);
      } else {
        // parse ISO "2004-11-02"
        birthDate = DateTime.parse(dob);
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      if (age < 0) age = 0;
      return '$age';
    } catch (e) {
      return 'N/A';
    }
  }

  static String getFormattedDate(dynamic value) {
    if (value == null) return "-";

    try {
      DateTime date;

      // If already DateTime
      if (value is DateTime) {
        date = value;
      }
      // If string → fix formats like "2025-12-03 03:07 PM"
      else if (value is String) {
        // Try normal parse
        try {
          date = DateTime.parse(value);
        } catch (_) {
          // Try manual parse for AM/PM formats
          date = DateFormat("yyyy-MM-dd hh:mm a").parse(value);
        }
      } else {
        return "-";
      }

      return DateFormat("dd-MM-yyyy hh:mm a").format(date);
    } catch (e) {
      return value.toString();
    }
  }

  Future<void> _showBillConfirmationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isPrinting = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text(
                "Payment Successful",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text("Do you want to print the bill now?"),
              actions: [
                /// ❌ NO → refresh
                TextButton(
                  onPressed: isPrinting
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          Navigator.pop(context, true); // ✅ refresh
                        },
                  child: const Text("No"),
                ),

                /// ✅ YES → print or cancel → refresh ALWAYS
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: isPrinting
                      ? null
                      : () async {
                          setDialogState(() => isPrinting = true);
                          Navigator.pop(ctx);

                          setState(() => _isBuildingPdf = true);

                          try {
                            final pdf = await buildPdf(
                              cellController: cellController,
                              dobController: dobController,
                              fee: widget.fee,
                              hospitalName: hospitalName!,
                              hospitalPlace: hospitalPlace!,
                              nameController: nameController,
                              logo: logo!,
                            );

                            if (mounted) {
                              setState(() => _isBuildingPdf = false);
                            }

                            // 🔑 user may print OR cancel – we don't care
                            await Printing.layoutPdf(
                              onLayout: (format) async => pdf.save(),
                            );
                          } catch (e) {
                            debugPrint("Print error: $e");
                          } finally {
                            if (mounted) {
                              // 🔥 ALWAYS refresh parent
                              Navigator.pop(context, true);
                            }
                          }
                        },
                  child: isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Yes, Print",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handlePayment() async {
    final amount = widget.fee['amount']?.toDouble() ?? 0.0;
    final paymentId = widget.fee['id'];
    final type = widget.fee['type'].toString().toUpperCase();

    final paymentResult = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentModal(registrationFee: amount),
    );

    if (paymentResult == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
      return;
    }
    final String paymentMode = paymentResult?['paymentMode'] ?? 'unknown';
    final prefs = await SharedPreferences.getInstance();

    // ✅ Payment succeeded → update backend
    setState(() => _isProcessing = true);
    final staffId = prefs.getString('userId');
    final response = await PaymentService().updatePayment(paymentId, {
      'status': 'PAID',
      // 'transactionId': paymentResult['transactionId'],
      "staff_Id": staffId.toString(),
      "paymentType": paymentMode,
      "updatedAt": _dateTime.toString(),
    });

    // final Id = widget.patient['Consultation']?[0]?['id'];
    final consultationId = widget.fee['consultation_Id'];

    if (type == 'REGISTRATIONFEE') {
      await ConsultationService().updateConsultation(consultationId, {
        "paymentStatus": true,
      });
    } else if (type == 'TESTINGFEESANDSCANNINGFEE') {
      final testings = widget.fee['TestingAndScanningPatients'];

      final testId = (testings != null && testings.isNotEmpty)
          ? testings[0]['payment_Id']
          : null;

      await TestingScanningService().updateTestAndScan(testId);
      await ConsultationService().updateConsultation(consultationId, {
        "queueStatus": 'PENDING',
      });
    } else {}
    // else if (type == 'MEDICINEFEEANDINJECTIONFEE') {
    // await ConsultationService().updateConsultation(Id, {
    // "paymentStatus": true,
    // });
    // }

    setState(() => _isProcessing = false);

    if (response != null && response['status'] == 'success' && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Payment Successful')));
      //Navigator.pop(context, true);
      await _showBillConfirmationDialog();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Failed to update payment status.')),
        );
      }
    }
  }

  Future<void> _updateSugarTest() async {
    try {
      final consultationId = widget.fee['consultation_Id'];
      final paymentId = widget.fee['id'];

      final consultation = widget.fee['Consultation'];
      final num paymentAmount = widget.fee['amount'] ?? 0;
      final num sugarFee = consultation?['sugarTestFee'] ?? 0;

      // 🔒 Safety check
      if (sugarFee <= 0) {
        return;
      }

      final num finalTotal = (paymentAmount - sugarFee).clamp(
        0,
        double.infinity,
      );

      /// 🔹 Update Payment Amount
      await PaymentService().updatePayment(paymentId, {
        'amount': finalTotal,
        'updatedAt': _dateTime.toString(),
      });

      /// 🔹 Update Consultation (remove sugar test)
      await ConsultationService().updateConsultation(consultationId, {
        "sugerTest": false,
        "sugerTestQueue": false,
        "sugarTestFee": 0,
      });

      /// 🔹 Update local UI state
      setState(() {
        widget.fee['amount'] = finalTotal;
        consultation['sugarTestFee'] = 0;
      });
    } catch (e) {
      setState(() {});
    }
  }

  // Future<void> _updateTestAndScan() async {
  //   final testings = widget.fee['TestingAndScanningPatients'];
  //
  //   final paymentId = widget.fee['id'];
  //
  //   final num paymentAmount = widget.fee['amount'] ?? 0;
  //   final num testFee = testings?['amount'] ?? 0;
  //
  //   // 🔒 Safety check
  //   if (testFee <= 0) {
  //     print('No test fee to remove');
  //     return;
  //   }
  //
  //   final num finalTotal = (paymentAmount - testFee).clamp(0, double.infinity);
  //
  //   /// 🔹 Update Payment Amount
  //   await PaymentService().updatePayment(paymentId, {
  //     'amount': finalTotal,
  //     'updatedAt': _dateTime.toString(),
  //   });
  //
  //   final testId = (testings != null && testings.isNotEmpty)
  //       ? testings[0]['payment_Id']
  //       : null;
  //   try {
  //     await ConsultationService().updateConsultation(testId, {
  //       "unSelectedOptions": '',
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }
  bool isValid(String? value) {
    return value != null &&
        value.trim() != 'null' &&
        value.trim().isNotEmpty &&
        value.trim() != '0' &&
        value.trim() != 'N/A' &&
        value.trim() != '-' &&
        value.trim() != '_' &&
        value.trim() != '-mg/dL';
  }

  bool hasAnyVital({
    String? temperature,
    String? bloodPressure,
    String? sugar,
    String? height,
    String? weight,
    String? BMI,
    String? PK,
    String? SpO2,
  }) {
    return isValid(temperature) ||
        isValid(bloodPressure) ||
        isValid(sugar) ||
        isValid(height) ||
        isValid(weight) ||
        isValid(BMI) ||
        isValid(PK) ||
        isValid(SpO2);
  }

  bool _isValid(String? value) {
    return value != null &&
        value.trim() != 'null' &&
        value.trim().isNotEmpty &&
        value.trim() != '0' &&
        value.trim() != 'N/A' &&
        value.trim() != '-' &&
        value.trim() != '_' &&
        value.trim() != '-mg/dL';
  }

  @override
  Widget build(BuildContext context) {
    final List tests = widget.fee["TestingAndScanningPatients"] ?? [];
    final consultation = widget.fee['Consultation'];
    final temperature = consultation['temperature'].toString();
    final bloodPressure = consultation['bp'] ?? '_';
    final sugar = consultation['sugar'] ?? '_';
    final height = consultation['height'].toString() ?? '_';
    final weight = consultation['weight'].toString() ?? '_';
    final BMI = consultation['BMI'].toString() ?? '_';
    final PK = consultation['PK'].toString() ?? '_';
    final SpO2 = consultation['SPO2'].toString() ?? '_';

    final num? registrationFee = consultation?['registrationFee'];
    final num? consultationFee =
        consultation?['consultationFee'] + registrationFee;
    final num? emergencyFee = consultation?['emergencyFee'];
    final num? sugarTestFee = consultation?['sugarTestFee'];
    final tokenNo =
        (consultation['tokenNo'] == null || consultation['tokenNo'] == 0)
        ? '-'
        : consultation['tokenNo'].toString();
    // final num totalAmount =
    //     (registrationFee ?? 0) +
    //     (consultationFee ?? 0) +
    //     (emergencyFee ?? 0) +
    //     (sugarTestFee ?? 0);

    final Color themeColor = const Color(0xFFBF955E);
    const Color background = Color(0xFFF8F8F8);
    bool hasSubAmounts(dynamic selectedOption) {
      if (selectedOption is Map) {
        return selectedOption.values.any((v) => v != null && v != 0);
      }

      if (selectedOption is List) {
        return selectedOption.any(
          (e) => e is Map && e['amount'] != null && e['amount'] != 0,
        );
      }

      return false;
    }

    List<MapEntry<String, num>> parseSelectedOption(dynamic selectedOption) {
      if (selectedOption is Map) {
        return selectedOption.entries
            .map(
              (e) => MapEntry(
                e.key.toString(),
                num.tryParse(e.value.toString()) ?? 0,
              ),
            )
            .where((e) => e.value > 0)
            .toList();
      }

      if (selectedOption is List) {
        return selectedOption
            .whereType<Map>()
            .map(
              (e) => MapEntry(
                e['name']?.toString() ?? '',
                num.tryParse(e['amount']?.toString() ?? '') ?? 0,
              ),
            )
            .where((e) => e.key.isNotEmpty && e.value > 0)
            .toList();
      }

      return [];
    }

    return Scaffold(
      backgroundColor: background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Fees Payment",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      int count = 0;
                      Navigator.popUntil(context, (route) => count++ >= 2);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧾 Bill Header
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "INVOICE / HOSPITAL BILL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Date: ${DateTime.now().toString().split(' ').first}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Text(
                        //   "Token No: ${widget.fee['Consultation']['tokenNo'] ?? '-'}",
                        //   style: TextStyle(
                        //     fontSize: 13,
                        //     color: Colors.grey[700],
                        //   ),
                        // ),
                        Row(
                          mainAxisSize: MainAxisSize
                              .min, // row takes minimal horizontal space
                          children: [
                            Text(
                              'Token No: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              tokenNo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const Divider(thickness: 1.2, height: 25),
                      ],
                    ),
                  ),

                  // 👤 Patient Information
                  const Text(
                    "Patient Details",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow("Name ", nameController.text),
                  _infoRow("PID ", idController.text),
                  _infoRow("Cell No ", cellController.text),
                  _infoRow("DOB ", dobController.text),
                  _infoRow("AGE ", calculateAge(dobController.text)),
                  _infoRow("Address ", addressController.text),
                  const Divider(thickness: 1.2, height: 30),

                  // 💳 Fee Details
                  if (widget.fee['type'] == 'REGISTRATIONFEE') ...[
                    Center(
                      child: const Text(
                        "Vitals",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Divider(thickness: 1.2, height: 30),

                    if (widget.fee['type'] == 'REGISTRATIONFEE')
                      if (hasAnyVital(
                        temperature: temperature,
                        bloodPressure: bloodPressure,
                        sugar: sugar,
                        height: height,
                        weight: weight,
                        BMI: BMI,
                        PK: PK,
                        SpO2: SpO2,
                      ))
                        _buildVitalsDetails(
                          temperature: temperature,
                          bloodPressure: bloodPressure,
                          sugar: sugar,
                          height: height,
                          weight: weight,
                          BMI: BMI,
                          PK: PK,
                          SpO2: SpO2,
                        ),

                    const Divider(thickness: 1.2, height: 30),
                  ],

                  // 💳 Fee Details
                  Center(
                    child: const Text(
                      "Fee Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Divider(thickness: 1.5, height: 20),
                  const SizedBox(height: 2),
                  if (widget.fee['type'] == 'REGISTRATIONFEE') ...[
                    // Row(
                    //   children: [
                    //     Text(
                    //       "${widget.fee['reason']}",
                    //       style: const TextStyle(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //     Spacer(),
                    //     Text(
                    //       "₹ ${feeController.text}",
                    //       textAlign: TextAlign.end,
                    //       style: const TextStyle(
                    //         fontSize: 15,
                    //         color: Colors.black87,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Column(
                      children: [
                        // feeRowWithRemove(
                        //   title: "Registration Fee",
                        //   amount: registrationFee,
                        //   removable: false, // ❌ disabled
                        // ),
                        feeRowWithRemove(
                          title: "Consultation Fee",
                          amount: consultationFee,
                          removable: false, // ❌ disabled
                        ),

                        feeRowWithRemove(
                          title: "Emergency Fee",
                          amount: emergencyFee,
                          removable: false, // ❌ disabled
                        ),

                        feeRowWithRemove(
                          title: "Sugar Test Fee",
                          amount: sugarTestFee,
                          removable: true, // ✅ enabled
                          onRemove: () {
                            _updateSugarTest();
                            setState(() {
                              consultation['sugarTestFee'] = 0;
                            });
                          },
                        ),
                      ],
                    ),

                    // _billRow(
                    //   "${widget.fee['reason']}",
                    //   "₹ ${feeController.text}",
                    // ),
                  ],
                  if (tests.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      "${widget.fee['reason']}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ...tests.map((t) {
                    //   final title = t["title"]?.toString() ?? "-";
                    //   final amount = t["amount"]?.toString() ?? "0";
                    //   final Map<String, dynamic> selectedOption =
                    //       Map<String, dynamic>.from(t['selectedOption'] ?? {});
                    //
                    //   return _billRow(title, selectedOption, "₹ $amount");
                    // }).toList(),
                    ...tests.expand((t) {
                      final title = t["title"]?.toString() ?? "-";
                      final amount = t["amount"]?.toString() ?? "0";
                      final selectedOption = t['selectedOptionAmounts'];

                      final bool showSubRows = hasSubAmounts(selectedOption);
                      final entries = showSubRows
                          ? parseSelectedOption(selectedOption)
                          : <MapEntry<String, num>>[];

                      return [
                        // ✅ ALWAYS show parent row
                        _billRow(title, amount, isBold: true, fontSize: 16),

                        // ✅ Show sub rows ONLY for new data
                        if (showSubRows)
                          ...entries.map(
                            (e) => _subBillRow(e.key, e.value.toString()),
                          ),

                        const SizedBox(height: 8),
                      ];
                    }),
                  ],

                  const Divider(thickness: 1.5, height: 25),

                  // 🧮 Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.index == 1) ...[
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 6),
                        Text('PAID', style: TextStyle(color: Colors.black)),

                        Spacer(),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Total : ₹ ${calculateTotal(widget.fee['amount'])}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 💰 Pay Button
                  widget.index == 0
                      ? Row(
                          children: [
                            Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isProcessing ? 120 : 140,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.receipt_long,
                                    color: Colors.white,
                                  ),
                                  label: _isProcessing
                                      ? const Text(
                                          "Processing...",
                                          style: TextStyle(color: Colors.white),
                                        )
                                      : const Text(
                                          "Pay Bill",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                  onPressed: _isProcessing
                                      ? null
                                      : _handlePayment,
                                ),
                              ),
                            ),
                            Spacer(),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final paymentId = widget.fee['id'];
                                final consultationId =
                                    widget.fee['consultation_Id'];
                                final staffId = prefs.getString('userId');
                                if (context.mounted) {
                                  _showCancelDialog(
                                    context,
                                    paymentId: paymentId,
                                    consultationId: consultationId,
                                    staffId: staffId,
                                  );
                                }
                              },
                              icon: const Icon(Icons.cancel, size: 22),
                              label: const Text(
                                "Cancel ",
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 🔹 Print Button
                            ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isLoading = true;
                                        _isBuildingPdf = true;
                                      });

                                      try {
                                        final pdf = await buildPdf(
                                          cellController: cellController,
                                          dobController: dobController,
                                          fee: widget.fee,
                                          hospitalName: hospitalName!,
                                          hospitalPlace: hospitalPlace!,
                                          nameController: nameController,
                                          logo: logo!,
                                        );

                                        await Printing.layoutPdf(
                                          onLayout: (format) async =>
                                              pdf.save(),
                                        );
                                      } finally {
                                        setState(() => _isLoading = false);
                                        setState(() => _isBuildingPdf = false);
                                      }
                                    },
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.print,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isLoading ? "Printing..." : "Print",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent.shade400,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                            ),

                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () async {
                                if (widget.fee['type'] == 'REGISTRATIONFEE') {
                                  await WhatsAppSendPaymentBill.sendRegistrationBill(
                                    phoneNumber: cellController.text.replaceAll(
                                      '+',
                                      '',
                                    ),
                                    patientName: nameController.text,
                                    patientId: idController.text,
                                    tokenNo: tokenNo,
                                    age: calculateAge(dobController.text),
                                    address: addressController.text,
                                    registrationFee:
                                        widget
                                            .fee['Consultation']?['registrationFee'] ??
                                        0,
                                    consultationFee:
                                        widget
                                            .fee['Consultation']?['consultationFee'] ??
                                        0,
                                    emergencyFee:
                                        widget
                                            .fee['Consultation']?['emergencyFee'] ??
                                        0,
                                    sugarTestFee:
                                        widget
                                            .fee['Consultation']?['sugarTestFee'] ??
                                        0,
                                    temperature: temperature,
                                    bloodPressure: bloodPressure,
                                    sugar: sugar,
                                    height: height,
                                    weight: weight,
                                    BMI: BMI,
                                    PK: PK,
                                    SpO2: SpO2,
                                  );
                                } else if (widget.fee['type'] ==
                                    'TESTINGFEESANDSCANNINGFEE') {
                                  final List tests =
                                      widget
                                          .fee['TestingAndScanningPatients'] ??
                                      [];

                                  if (tests.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "No testing data to send",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  await WhatsAppSendPaymentBill.sendTestingBill(
                                    phoneNumber: cellController.text.replaceAll(
                                      '+',
                                      '',
                                    ),
                                    patientName: nameController.text,
                                    patientId: idController.text,
                                    tokenNo: tokenNo,
                                    age: calculateAge(dobController.text),
                                    address: addressController.text,
                                    tests: List<Map<String, dynamic>>.from(
                                      tests,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),

                            // 🔹 Share Button
                            // ElevatedButton.icon(
                            //   onPressed: () async {
                            //     final pdf = await buildPdf(
                            //       cellController: cellController,
                            //       dobController: dobController,
                            //       fee: widget.fee,
                            //       hospitalName: hospitalName!,
                            //       hospitalPlace: hospitalPlace!,
                            //       nameController: nameController,
                            //       logo: logo!,
                            //     );
                            //     await Printing.sharePdf(
                            //       bytes: await pdf.save(),
                            //       filename: "hospital_bill.pdf",
                            //     );
                            //   },
                            //
                            //   icon: const Icon(
                            //     Icons.share,
                            //     color: Colors.white,
                            //   ),
                            //   label: const Text(
                            //     "Share",
                            //     style: TextStyle(
                            //       color: Colors.white,
                            //       fontSize: 16,
                            //     ),
                            //   ),
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor: Colors.green,
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: 12,
                            //       vertical: 12,
                            //     ),
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(12),
                            //     ),
                            //     elevation: 5,
                            //   ),
                            // ),
                          ],
                        ),
                ],
              ),
            ),
          ),

          // 🌀 Loading Overlay
          // if (_isProcessing)
          //   Container(
          //     color: Colors.black38,
          //     child: const Center(
          //       child: CircularProgressIndicator(color: Colors.white),
          //     ),
          //   ),
          // 🌀 Loading Overlay (Payment OR PDF building)
          if (_isProcessing || _isBuildingPdf)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalsDetails({
    String? temperature,
    String? bloodPressure,
    String? sugar,
    String? height,
    String? weight,
    String? BMI,
    String? PK,
    String? SpO2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        const SizedBox(height: 8),

        if (_isValid(temperature)) _vitalRow("Temperature", "$temperature °F"),

        if (_isValid(bloodPressure)) _vitalRow("BP", bloodPressure!),

        if (_isValid(sugar)) _vitalRow("Sugar", "$sugar mg/dL"),

        if (_isValid(weight)) _vitalRow("Weight", "$weight kg"),

        if (_isValid(height)) _vitalRow("Height", "$height cm"),

        if (_isValid(BMI)) _vitalRow("BMI", BMI!),

        if (_isValid(PK)) _vitalRow("PR", "$PK bpm"),

        if (_isValid(SpO2)) _vitalRow("SpO₂", "$SpO2 %"),
      ],
    );
  }

  Widget _vitalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label :",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget feeRowWithRemove({
    required String title,
    required num? amount,
    required bool removable,
    VoidCallback? onRemove,
  }) {
    if (amount == null || amount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: feeRow(title, amount)),

          /// Remove Icon
          if (widget.index != 1) ...[
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: removable ? Colors.redAccent : Colors.grey,
              ),
              onPressed: removable ? onRemove : null, // 🔒 disable others
              tooltip: removable ? "Remove $title" : null,
            ),
          ],
        ],
      ),
    );
  }

  //////////////////////////////////////////////feee///////////////////////////
  Widget feeRow(String title, num? amount, {bool isTotal = false}) {
    if (amount == null || amount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 17 : 15,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.black : Colors.grey[800],
              ),
            ),
          ),
          Text(
            "₹ ${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: isTotal ? 17 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context, {
    required int paymentId,
    required int consultationId,
    required String? staffId,
  }) {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text(
                "Cancel Confirmation",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                "Are you sure you want to cancel this payment and consultation?",
              ),
              actions: [
                /// ❌ CANCEL BUTTON
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black),
                  ),
                ),

                /// ✅ OK BUTTON WITH LOADER
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          try {
                            final dateTime = DateTime.now();

                            /// 🔹 Update Payment
                            await PaymentService().updatePayment(paymentId, {
                              'status': 'CANCELLED',
                              'staff_Id': staffId.toString(),
                              'updatedAt': dateTime.toString(),
                            });

                            /// 🔹 Update Consultation
                            await ConsultationService().updateConsultation(
                              consultationId,
                              {'status': 'CANCELLED'},
                            );

                            if (context.mounted) {
                              Navigator.pop(ctx); // close dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("❌ Cancelled successfully"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            setState(() => isLoading = false);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to cancel"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("OK", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
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
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              child: pw.Text(
                title,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey900),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
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

  // --- UI Helpers ---
  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 15,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            "₹ $value",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subBillRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "• $label",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Text(
            "₹ $value",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // String _calculateTax(dynamic amount) {
  //   if (amount == null) return "0.00";
  //   double tax = (amount * 0.05);
  //   return tax.toStringAsFixed(0);
  // }

  static String calculateTotal(dynamic amount) {
    if (amount == null) return "0.00";
    double total = (amount * 1.00);
    return total.toStringAsFixed(0);
  }

  static String extractString(dynamic value, [String? key]) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map && key != null) {
      return value[key]?.toString() ?? '';
    }
    return value.toString();
  }

  static String extractName(dynamic name) {
    if (name == null) return '';
    if (name is String) return name;
    if (name is Map) {
      final first = name['first'] ?? '';
      final last = name['last'] ?? '';
      return '$first $last'.trim();
    }
    return name.toString();
  }
}
