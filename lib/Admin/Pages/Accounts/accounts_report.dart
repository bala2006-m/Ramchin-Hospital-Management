import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hospitrax/Admin/Pages/Accounts/widgets/accounts_report_pdf.dart';
import 'package:hospitrax/Admin/Pages/Accounts/widgets/report_filter_widget.dart';
import 'package:hospitrax/Services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountsReport extends StatefulWidget {
  const AccountsReport({super.key});

  @override
  State<AccountsReport> createState() => _AccountsReportState();
}

class _AccountsReportState extends State<AccountsReport> {
  final _paymentService = PaymentService();

  List<dynamic> _allPayments = [];
  List<dynamic> _filteredPayments = [];
  double _total = 0;

  DateFilter _currentFilter = DateFilter.day;
  DateTime _selectedDate = DateTime.now();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  bool _isGeneratingPdf = false; // PDF Loading

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _loadPayments();
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

    // Convert all dates to DateTime to avoid parsing errors
    for (var p in result) {
      try {
        p['createdAt'] = DateTime.parse(p['createdAt']);
      } catch (_) {
        p['createdAt'] = DateFormat("yyyy-MM-dd hh:mm a").parse(p['createdAt']);
      }
    }

    setState(() {
      _allPayments = result;
      // Default filter: current day
      _applyReportFilter(
        reportType: DateFilter.day,
        selectedDate: DateTime.now(),
      );
    });
  }

  void _applyReportFilter({
    required DateFilter reportType,
    required DateTime selectedDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    _currentFilter = reportType;
    _selectedDate = selectedDate;
    _fromDate = fromDate;
    _toDate = toDate;

    List<dynamic> filtered = [];

    for (final p in _allPayments) {
      final createdAt = p['createdAt'] as DateTime;
      bool match = false;

      switch (reportType) {
        case DateFilter.day:
          match =
              createdAt.year == selectedDate.year &&
              createdAt.month == selectedDate.month &&
              createdAt.day == selectedDate.day;
          break;
        case DateFilter.month:
          match =
              createdAt.year == selectedDate.year &&
              createdAt.month == selectedDate.month;
          break;
        case DateFilter.year:
          match = createdAt.year == selectedDate.year;
          break;
        case DateFilter.periodical:
          if (fromDate != null && toDate != null) {
            match =
                !createdAt.isBefore(fromDate) &&
                !createdAt.isAfter(toDate.add(const Duration(days: 1)));
          }
          break;
      }

      if (match) filtered.add(p);
    }

    setState(() {
      _filteredPayments = filtered;
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _total = _filteredPayments.fold(
      0,
      (sum, p) => sum + double.parse(p['amount'].toString()),
    );
  }

  Future<void> _generatePdf() async {
    if (_filteredPayments.isEmpty) return;

    setState(() => _isGeneratingPdf = true);
    await AccountsReportPdf.generate(
      payments: _filteredPayments,
      total: _total,
      hospitalName: hospitalName ?? "Unknown Hospital",
      hospitalPlace: hospitalPlace ?? "",
      hospitalPhoto: hospitalPhoto ?? "",
    );
    setState(() => _isGeneratingPdf = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // ---------------- FILTER WIDGET ----------------
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ReportFilterWidget(onApply: _applyReportFilter),
          ),

          // ---------------- TOTAL & PDF BUTTON ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Amount",
                          style: TextStyle(fontSize: 14, color: Colors.brown),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹ ${_total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),

                    // Generate PDF Button
                    _isGeneratingPdf
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _generatePdf,
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Generate PDF",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBF955E),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // ---------------- PAYMENTS LIST ----------------
          Expanded(
            child: _filteredPayments.isEmpty
                ? const Center(
                    child: Text(
                      "No data available",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredPayments.length,
                    itemBuilder: (_, i) {
                      final p = _filteredPayments[i];
                      final date = p['createdAt'] as DateTime;

                      // Map type to user-friendly text and colors
                      String typeText = "Other";
                      Color badgeColor = Colors.blueGrey.shade400;
                      Color cardColor = Colors.white;

                      switch (p['type']) {
                        case 'REGISTRATIONFEE':
                          typeText = "Registration Fee";
                          badgeColor = Colors.blue.shade700;
                          cardColor = Colors.blue.shade50;
                          break;
                        case 'TESTINGFEESANDSCANNINGFEE':
                          typeText = "Test & Scan Fee";
                          badgeColor = Colors.green.shade700;
                          cardColor = Colors.green.shade50;
                          break;
                      }

                      return Card(
                        color: cardColor,
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.brown.shade300,
                                child: const Icon(
                                  Icons.payment,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Amount
                                    Text(
                                      "₹ ${double.parse(p['amount'].toString()).toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Type Badge
                                    Text(
                                      typeText,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 6),
                                    // Date
                                    Text(
                                      DateFormat(
                                        "dd MMM yyyy, hh:mm a",
                                      ).format(date),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(110),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFBF955E), Color(0xFFA67C52)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
                const SizedBox(width: 8),
                const Text(
                  "Accounts Report",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
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
