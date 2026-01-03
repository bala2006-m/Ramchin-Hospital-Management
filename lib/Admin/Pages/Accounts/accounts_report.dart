import 'package:flutter/material.dart';
import 'package:hospitrax/Admin/Pages/Accounts/widgets/accounts_report_pdf.dart';
import 'package:hospitrax/Admin/Pages/Accounts/widgets/report_filter_widget.dart';
import 'package:hospitrax/Services/payment_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/IncomeExpence_Service.dart';
import '../../../Services/drawer_Service.dart';

class PaymentTotals {
  // ---------------- Amount Totals ----------------
  double totalRegister = 0;
  double totalRegisterCash = 0;
  double totalRegisterOnline = 0;
  double totalRegistrationFee = 0;
  double totalSugarFee = 0;
  double totalEmergencyFee = 0;
  double totalDoctorFee = 0;
  Map<String, Map<String, dynamic>> doctorFeeTotals = {};

  double totalMedical = 0;
  double totalMedicalCash = 0;
  double totalMedicalOnline = 0;

  double totalTest = 0;
  double totalTestCash = 0;
  double totalTestOnline = 0;
  double totalScan = 0;
  double totalScanCash = 0;
  double totalScanOnline = 0;

  // ---------------- Count Fields ----------------
  int totalRegistrationFeeCount = 0;
  int totalSugarFeeCount = 0;
  int totalEmergencyFeeCount = 0;

  // ---------------- Sub-Test/Scan Maps ----------------
  Map<String, int> testCounts = {}; // e.g., {"Blood Test": 3, "Sugar Test": 2}
  Map<String, int> scanCounts = {}; // e.g., {"X-ray": 2, "MRI": 1}

  // ---------------- Grand Total ----------------
  double get grandTotal => totalRegister + totalMedical + totalTest + totalScan;
}

class AccountsReport extends StatefulWidget {
  const AccountsReport({super.key});

  @override
  State<AccountsReport> createState() => _AccountsReportState();
}

class _AccountsReportState extends State<AccountsReport> {
  final _paymentService = PaymentService();
  final _incexpService = IncomeExpenseService();
  final _drawerService = DrawerService();

  List<dynamic> _allPayments = [];
  List<dynamic> _filteredPayments = [];
  PaymentTotals _paymentTotals = PaymentTotals();
  double _grandTotal = 0;

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  double _totalCashIncome = 0;
  double _totalExpenses = 0;
  double _totalIncomes = 0;
  double _totalDrawing = 0;
  double _cashInHand = 0;

  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _loadPayments();

    // 🔹 Default: current day report
    final now = DateTime.now();

    await _applyReportFilter(reportType: DateFilter.day, selectedDate: now);
  }

  DateTime parseAppDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;

    final str = value.toString();

    try {
      // Try ISO first
      return DateTime.parse(str);
    } catch (_) {
      // Fallback to your format
      return DateFormat("yyyy-MM-dd hh:mm a").parse(str);
    }
  }

  Future<void> _loadExpenses({
    required DateTime from,
    required DateTime to,
  }) async {
    final fetched = await _incexpService.getIncomeExpenseService();

    final filtered = fetched.where((e) {
      final createdAt = parseAppDate(e['createdAt']);
      return !createdAt.isBefore(from) && !createdAt.isAfter(to);
    }).toList();

    _totalExpenses = filtered
        .where((e) => e['type']?.toString().toUpperCase() == "EXPENSE")
        .fold(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());

    _totalIncomes = filtered
        .where((e) => e['type']?.toString().toUpperCase() == "INCOME")
        .fold(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());
  }

  Future<void> _loadDrawings({
    required DateTime from,
    required DateTime to,
  }) async {
    final fetched = await _drawerService.getDrawers();

    final filtered = fetched.where((d) {
      final createdAt = parseAppDate(d['createdAt']);
      return !createdAt.isBefore(from) && !createdAt.isAfter(to);
    }).toList();

    _totalDrawing = filtered.fold(
      0.0,
      (sum, d) => sum + (d['amount'] as num).toDouble(),
    );
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hospitalName = prefs.getString('hospitalName') ?? "Unknown Hospital";
      hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown Place";
      hospitalPhoto =
          prefs.getString('hospitalPhoto') ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  Future<void> _loadPayments() async {
    final result = await _paymentService.getAllPaidShowAccounts();
    for (var p in result) {
      try {
        p['createdAt'] = DateTime.parse(p['createdAt']);
      } catch (_) {
        p['createdAt'] = DateFormat("yyyy-MM-dd hh:mm a").parse(p['createdAt']);
      }
    }
    setState(() {
      _allPayments = result;
    });
  }

  Future<void> _applyReportFilter({
    required DateFilter reportType,
    required DateTime selectedDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    late DateTime from;
    late DateTime to;

    // ---------------- Determine date range ----------------
    switch (reportType) {
      case DateFilter.day:
        from = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        to = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59,
        );
        break;

      case DateFilter.month:
        from = DateTime(selectedDate.year, selectedDate.month, 1);
        to = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
        break;

      case DateFilter.year:
        from = DateTime(selectedDate.year, 1, 1);
        to = DateTime(selectedDate.year, 12, 31, 23, 59, 59);
        break;

      case DateFilter.periodical:
        if (fromDate == null || toDate == null) return;
        from = fromDate;
        to = toDate;
        break;
    }

    // ---------------- Filter Payments ----------------
    final filtered = _allPayments.where((p) {
      final createdAt = p['createdAt'] as DateTime;
      return !createdAt.isBefore(from) && !createdAt.isAfter(to);
    }).toList();

    // ---------------- Load Expenses & Drawing (SAME RANGE) ----------------
    await _loadExpenses(from: from, to: to);
    await _loadDrawings(from: from, to: to);

    setState(() {
      _filteredPayments = filtered;
    });

    _calculateTotals();
  }

  void _calculateTotals() {
    final totals = PaymentTotals();

    Map<String, int> testCounts = {};
    Map<String, int> scanCounts = {};

    for (var p in _filteredPayments) {
      final type = (p['type'] ?? "").toString().toUpperCase();
      final amount = (p['amount'] ?? 0).toDouble();
      final paymentType = (p['paymentType'] ?? "").toString().toUpperCase();
      final consultation = p['Consultation'];

      // ---------------- REGISTRATION ----------------
      if (type == "REGISTRATIONFEE") {
        totals.totalRegister += amount;

        if (paymentType == "MANUALPAY") totals.totalRegisterCash += amount;
        if (paymentType == "ONLINEPAY") totals.totalRegisterOnline += amount;

        if (consultation != null) {
          totals.totalRegistrationFee += (consultation['registrationFee'] ?? 0)
              .toDouble();
          totals.totalSugarFee += (consultation['sugarTestFee'] ?? 0)
              .toDouble();
          totals.totalEmergencyFee += (consultation['emergencyFee'] ?? 0)
              .toDouble();

          final double consultFee = (consultation['consultationFee'] ?? 0)
              .toDouble();
          totals.totalDoctorFee += consultFee;

          final doctorId = consultation['doctor_Id']?.toString();
          final doctorName = getDoctorName(p);

          if (doctorId != null && doctorName.isNotEmpty) {
            totals.doctorFeeTotals.putIfAbsent(
              doctorId,
              () => {'name': doctorName, 'total': 0.0},
            );
            totals.doctorFeeTotals[doctorId]!['total'] =
                (totals.doctorFeeTotals[doctorId]!['total'] as double) +
                consultFee;
          }
        }
      }
      // ---------------- TEST & SCAN ----------------
      else if (type == "TESTINGFEESANDSCANNINGFEE") {
        for (var entry in p["TestingAndScanningPatients"] ?? []) {
          final subType = (entry["type"] ?? "").toString();
          final subAmt = (entry["amount"] ?? 0).toDouble();

          if (subType.toLowerCase().contains("test")) {
            totals.totalTest += subAmt;
            if (paymentType == "MANUALPAY") totals.totalTestCash += subAmt;
            if (paymentType == "ONLINEPAY") totals.totalTestOnline += subAmt;
            testCounts[subType] = (testCounts[subType] ?? 0) + 1;
          } else {
            totals.totalScan += subAmt;
            if (paymentType == "MANUALPAY") totals.totalScanCash += subAmt;
            if (paymentType == "ONLINEPAY") totals.totalScanOnline += subAmt;
            scanCounts[subType] = (scanCounts[subType] ?? 0) + 1;
          }
        }
      }
      // ---------------- MEDICAL ----------------
      else if (type == "MEDICINETONICINJECTIONFEES") {
        totals.totalMedical += amount;
        if (paymentType == "MANUALPAY") totals.totalMedicalCash += amount;
        if (paymentType == "ONLINEPAY") totals.totalMedicalOnline += amount;
      }
    }

    // ---------------- GRAND TOTALS ----------------
    final totalCashPayments =
        totals.totalRegisterCash +
        totals.totalTestCash +
        totals.totalScanCash +
        totals.totalMedicalCash +
        _totalIncomes; // other income (cash)

    final totalOnlinePayments =
        totals.totalRegisterOnline +
        totals.totalTestOnline +
        totals.totalScanOnline +
        totals.totalMedicalOnline;

    final balance = totalCashPayments - _totalExpenses;

    _cashInHand = balance - _totalDrawing;

    setState(() {
      _paymentTotals = totals;
      _grandTotal = totals.grandTotal + _totalIncomes; // include other income
      _totalCashIncome = totalCashPayments;
    });
  }

  String getDoctorName(Map<String, dynamic> payment) {
    try {
      final doctor = payment['Hospital']['Admins'].firstWhere(
        (a) => a['user_Id'] == payment['Consultation']['doctor_Id'],
      );
      return doctor['name'] ?? "Unknown Doctor";
    } catch (_) {
      return "Unknown Doctor";
    }
  }

  String formatAmount(double value) {
    if (value >= 10000000) return "${(value / 10000000).toStringAsFixed(1)}Cr";
    if (value >= 100000) return "${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}K";
    return value.toStringAsFixed(1);
  }

  // Future<void> _generatePdf() async {
  //   if (_filteredPayments.isEmpty || _isGeneratingPdf) return;
  //
  //   try {
  //     setState(() => _isGeneratingPdf = true);
  //
  //     await AccountsReportPdf.generate(
  //       payments: _filteredPayments,
  //       hospitalName: hospitalName ?? "Unknown Hospital",
  //       hospitalPlace: hospitalPlace ?? "",
  //       hospitalPhoto: hospitalPhoto ?? "",
  //       expenses: _totalExpenses,
  //       drawingOut: _totalDrawing,
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isGeneratingPdf = false);
  //     }
  //   }
  // }

  Future<void> _generatePdf() async {
    if (_filteredPayments.isEmpty || _isGeneratingPdf) return;

    try {
      setState(() => _isGeneratingPdf = true);

      await AccountsReportPdf.generate(
        payments: _filteredPayments,
        hospitalName: hospitalName ?? "Unknown Hospital",
        hospitalPlace: hospitalPlace ?? "",
        income: _totalIncomes,
        expenses: _totalExpenses,
        drawingOut: _totalDrawing,

        // ✅ ADD THESE
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Widget _fullRowCard(String title, double amount, {Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            "₹ ${formatAmount(amount)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> doctorTotals = {};
    for (var entry in _paymentTotals.doctorFeeTotals.entries) {
      doctorTotals[entry.value['name']] = entry.value['total'] as double;
    }

    bool hasData = _filteredPayments.isNotEmpty;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportFilterWidget(onApply: _applyReportFilter),
            const SizedBox(height: 20),
            // ---------------------Generate Pdf ----------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: hasData && !_isGeneratingPdf ? _generatePdf : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                    backgroundColor: hasData
                        ? Colors.green
                        : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    "Generate PDF",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---------------- GRAND TOTAL + PDF ----------------
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Grand Total",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹ ${formatAmount(_grandTotal)}",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------- REGISTRATION GROUP ----------------
            _buildGroupCard(
              title: "Registration & Consultation",
              children: [
                _fullRowCard(
                  "Registration Fee",
                  _paymentTotals.totalRegistrationFee,
                  color: Colors.blue.shade50,
                ),
                _fullRowCard(
                  "Consultation Fee",
                  _paymentTotals.totalDoctorFee,
                  color: Colors.purple.shade50,
                ),
                _fullRowCard(
                  "Sugar Test Fee",
                  _paymentTotals.totalSugarFee,
                  color: Colors.green.shade50,
                ),
                _fullRowCard(
                  "Emergency Fee",
                  _paymentTotals.totalEmergencyFee,
                  color: Colors.red.shade50,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---------------- TEST & SCAN GROUP ----------------
            _buildGroupCard(
              title: "Test & Scan Fees",
              children: [
                _fullRowCard(
                  "Test Fee",
                  _paymentTotals.totalTest,
                  color: Colors.teal.shade50,
                ),
                _fullRowCard(
                  "Scan Fee",
                  _paymentTotals.totalScan,
                  color: Colors.cyan.shade50,
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildGroupCard(
              title: "Cash Summary",
              children: [
                _fullRowCard(
                  "Total Cash Income",
                  _totalCashIncome,
                  color: Colors.green.shade50,
                ),
                _fullRowCard(
                  "Expenses",
                  _totalExpenses,
                  color: Colors.red.shade50,
                ),
                _fullRowCard(
                  "Other Income",
                  _totalIncomes,
                  color: Colors.yellow.shade50,
                ),
                _fullRowCard(
                  "Balance",
                  _totalCashIncome - _totalExpenses,
                  color: Colors.blue.shade50,
                ),
                _fullRowCard(
                  "Drawing Out",
                  _totalDrawing,
                  color: Colors.orange.shade50,
                ),
                _fullRowCard(
                  "Cash in Hand",
                  _cashInHand,
                  color: Colors.purple.shade50,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------------- MEDICAL GROUP ----------------
            _buildGroupCard(
              title: "Medical / Injection / Tonic",
              children: [
                _fullRowCard(
                  "Medical / Injection / Tonic",
                  _paymentTotals.totalMedical,
                  color: Colors.orange.shade50,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "Doctor-wise Consultation Fees",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ---------------- DOCTOR WISE SCROLLABLE ----------------
            doctorTotals.isEmpty
                ? const Text("No doctor fees found.")
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: doctorTotals.entries.map((e) {
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹ ${formatAmount(e.value)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPER: GROUP CARD ----------------
  Widget _buildGroupCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFBF955E),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
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
                  " Accounts Report ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
