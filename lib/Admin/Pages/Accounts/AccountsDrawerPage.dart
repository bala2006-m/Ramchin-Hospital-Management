import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hospitrax/Services/payment_service.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Mediacl_Staff/Pages/OutPatient/Page/InjectionPage.dart';
import '../../../Pages/NotificationsPage.dart';
import '../../../Services/drawer_Service.dart';
import 'FinancePage.dart';

class AccountDrawerPage extends StatefulWidget {
  const AccountDrawerPage({super.key});

  @override
  _AccountDrawerPageState createState() => _AccountDrawerPageState();
}

class _AccountDrawerPageState extends State<AccountDrawerPage> {
  final DrawerService _drawerService = DrawerService();
  final PaymentService _paymentService = PaymentService();

  bool showForm = false;
  bool _loading = false;
  bool _submitting = false;

  final TextEditingController reasonController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String type = 'OUT';

  List<Map<String, dynamic>> drawers = [];
  List<Map<String, dynamic>> payments = [];
  double total = 0;

  // Hospital info
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  String? _dateTime;
  double totalIN = 0;
  double totalOUT = 0;
  double balance = 0;
  double totalPayment = 0;
  String? _error;
  // ✅ Default = current MONTH
  DateFilter _selectedDateFilter = DateFilter.month;

  // ✅ Default = 1st day of current month
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  List<Map<String, dynamic>> visibleDrawers = [];
  List<Map<String, dynamic>> visiblePayments = [];

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    // fetchDrawers();
    _updateTime();
    // fetchPayments();
    fetchPayments().then((_) {
      fetchDrawers(); // Correct balance after BOTH load
    });
  }

  void _updateTime() {
    _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();

    hospitalName = prefs.getString('hospitalName') ?? '';
    hospitalPlace = prefs.getString('hospitalPlace') ?? '';
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";

    setState(() {});
  }

  // Future<void> fetchDrawers() async {
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //   });
  //
  //   try {
  //     final fetchedDrawers = await _drawerService.getDrawers();
  //
  //     setState(() {
  //       drawers = fetchedDrawers.map((e) => e as Map<String, dynamic>).toList();
  //
  //       // Reset totals
  //       totalIN = 0;
  //       totalOUT = 0;
  //
  //       for (var d in drawers) {
  //         final double amount = (d['amount'] as num).toDouble();
  //         final String type = (d['type'] ?? 'IN').toUpperCase();
  //
  //         if (type == 'IN') {
  //           totalIN += amount;
  //         } else {
  //           totalOUT += amount;
  //         }
  //       }
  //
  //       balance = totalPayment + totalIN - totalOUT;
  //
  //       _loading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _error = "Error fetching drawers: $e";
  //       _loading = false;
  //     });
  //   }
  // }
  Future<void> fetchDrawers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fetchedDrawers = await _drawerService.getDrawers();

      drawers = fetchedDrawers
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _applyDrawerFilter(); // apply current filter

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error fetching drawers: $e";
        _loading = false;
      });
    }
  }

  void _applyDrawerFilter() {
    if (drawers.isEmpty) {
      setState(() {
        visibleDrawers = [];
        totalIN = 0;
        totalOUT = 0;
        balance = totalPayment - totalOUT;
      });
      return;
    }

    List<Map<String, dynamic>> filtered = [];

    for (var d in drawers) {
      final createdAtStr = d['createdAt'].toString();

      DateTime? dt;
      try {
        dt = DateFormat("yyyy-MM-dd hh:mm a").parse(createdAtStr);
      } catch (_) {
        continue;
      }

      if (_selectedDateFilter == DateFilter.day) {
        if (dt.year == _selectedDate.year &&
            dt.month == _selectedDate.month &&
            dt.day == _selectedDate.day) {
          filtered.add(d);
        }
      }

      if (_selectedDateFilter == DateFilter.month) {
        if (dt.year == _selectedDate.year && dt.month == _selectedDate.month) {
          filtered.add(d);
        }
      }

      if (_selectedDateFilter == DateFilter.year) {
        if (dt.year == _selectedDate.year) {
          filtered.add(d);
        }
      }
    }

    // Recalculate totals
    double inAmount = 0;
    double outAmount = 0;

    for (var d in filtered) {
      final double amount = (d['amount'] as num).toDouble();
      final type = d['type'].toString().toUpperCase();

      if (type == 'IN') {
        inAmount += amount;
      } else {
        outAmount += amount;
      }
    }

    setState(() {
      visibleDrawers = filtered;
      totalIN = inAmount;
      totalOUT = outAmount;
      balance = totalPayment + totalIN - totalOUT;
    });
  }

  Future<void> fetchPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fetchedPayments = await _paymentService.getAllPaidShowAccounts();

      payments = fetchedPayments
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _applyPaymentFilter(); // filter after fetching

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = "Error fetching Paid Payments: $e";
        _loading = false;
      });
    }
  }

  // Future<void> fetchPayments() async {
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //   });
  //
  //   try {
  //     final fetchedPayments = await _paymentService.getAllPaidShowAccounts();
  //
  //     // Convert list of dynamic to list of map
  //     final List<Map<String, dynamic>> parsedPayments = fetchedPayments
  //         .map((e) => Map<String, dynamic>.from(e))
  //         .toList();
  //
  //     double newTotalPayment = 0.0;
  //
  //     for (var p in parsedPayments) {
  //       // Add ONLY the main amount
  //       final double amount = (p['amount'] as num).toDouble();
  //       newTotalPayment += amount;
  //     }
  //
  //     setState(() {
  //       payments = parsedPayments;
  //
  //       totalPayment = newTotalPayment; // only main amount counted
  //
  //       balance = totalPayment + totalIN - totalOUT;
  //
  //       _loading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _error = "Error fetching Paid Payments: $e";
  //       _loading = false;
  //     });
  //   }
  // }
  void _applyPaymentFilter() {
    if (payments.isEmpty) {
      setState(() {
        visiblePayments = [];
        totalPayment = 0;
        balance = totalIN - totalOUT;
      });
      return;
    }

    List<Map<String, dynamic>> filtered = [];

    for (var p in payments) {
      final createdAtStr = p['createdAt'].toString();

      DateTime? dt;
      try {
        dt = DateFormat("yyyy-MM-dd hh:mm a").parse(createdAtStr);
      } catch (_) {
        continue;
      }

      if (_selectedDateFilter == DateFilter.day) {
        if (dt.year == _selectedDate.year &&
            dt.month == _selectedDate.month &&
            dt.day == _selectedDate.day) {
          filtered.add(p);
        }
      }

      if (_selectedDateFilter == DateFilter.month) {
        if (dt.year == _selectedDate.year && dt.month == _selectedDate.month) {
          filtered.add(p);
        }
      }

      if (_selectedDateFilter == DateFilter.year) {
        if (dt.year == _selectedDate.year) {
          filtered.add(p);
        }
      }
    }

    double newPaymentTotal = 0;

    for (var p in filtered) {
      newPaymentTotal += (p['amount'] as num).toDouble();
    }
    setState(() {
      visiblePayments = filtered;
      totalPayment = newPaymentTotal;
      balance = totalPayment + totalIN - totalOUT;
    });
  }

  void _applyFilter() {
    _applyDrawerFilter();
    _applyPaymentFilter();
  }

  Future<void> createDrawer() async {
    if (reasonController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reason and amount.')),
      );
      return;
    }

    final double enteredAmount =
        double.tryParse(amountController.text.trim()) ?? 0;

    // ❌ Must not allow negative amount
    if (enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }

    // ❌ If OUT, check balance
    if (type == "OUT") {
      double amount = double.tryParse(amountController.text.trim()) ?? 0;

      if (amount > balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Your current balance is low: ₹$balance")),
        );
        return; // stop submit
      }
    }

    // ❌ If NO totalPayment → block OUT submissions
    if (totalPayment == 0 && type == "OUT") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot add OUT. No payments available."),
        ),
      );
      return;
    }

    // ------ VALIDATION DONE ------
    setState(() {
      _submitting = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();

    final admin_Id = prefs.getString('userId');
    final hospitalId = prefs.getString('hospitalId');

    final data = {
      'hospital_Id': int.parse(hospitalId!),
      'reason': reasonController.text.trim(),
      'amount': enteredAmount,
      'type': type,
      'admin_Id': admin_Id,
      'createdAt': _dateTime,
    };

    try {
      await _drawerService.createDrawer(data);
      reasonController.clear();
      amountController.clear();

      setState(() {
        showForm = false;
        _submitting = false;
      });

      await fetchDrawers();
    } catch (e) {
      setState(() {
        _error = "Error creating drawer: $e";
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(_paymentService);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              _buildHospitalCard(),
              const SizedBox(height: 4),
              _buildDateFilterRow(),
              const SizedBox(height: 2),
              _buildTotalCard(),
              _buildAddDrawerButton(),
              if (showForm) _buildFormCard(),
              if (_error != null) _buildErrorCard(_error!),
              const SizedBox(height: 8),
              Container(
                height: 400,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: _loading
                    ? _buildLoadingIndicator()
                    : visibleDrawers.isEmpty
                    ? _buildNoDataMessage()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: visibleDrawers.length,
                        itemBuilder: (context, index) {
                          final drawer = visibleDrawers[index];
                          final drawerType =
                              (drawer['type'] as String?)?.toUpperCase() ??
                              'IN';
                          final isIncome = drawerType == 'IN';
                          final String typeLetter = isIncome ? "  IN  " : "OUT";

                          final Color cardColor = isIncome
                              ? Colors.lightBlue.shade100
                              : Colors.red.shade100;

                          final Color textColor = isIncome
                              ? Colors.blue.shade900
                              : Colors.red.shade900;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 10,
                              left: 8,
                              right: 18,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  child: Text(
                                    typeLetter,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        drawer['reason'] ?? '',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        drawer['admin_Id'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹ ${(drawer['amount'] ?? 0).toString()}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: primaryColor,
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
                const Text(
                  " Drawing ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20), // adjust spacing from top
        child: Text(
          "No Drawing Added",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.network(
              hospitalPhoto ?? "",
              height: 60,
              width: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_hospital,
                color: Colors.white,
                size: 55,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hospitalPlace ?? "",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterRow() {
    // Dynamic chip text
    String getLabel(DateFilter key) {
      switch (key) {
        case DateFilter.day:
          return _selectedDateFilter == DateFilter.day
              ? DateFormat('dd MMM').format(_selectedDate)
              : "Day";

        case DateFilter.month:
          return _selectedDateFilter == DateFilter.month
              ? DateFormat('MMM').format(_selectedDate)
              : "Month";

        case DateFilter.year:
          return _selectedDateFilter == DateFilter.year
              ? DateFormat('yyyy').format(_selectedDate)
              : "Year";
      }
    }

    // Chip Builder
    Widget buildChip(DateFilter key) {
      final bool isSelected = _selectedDateFilter == key;

      return GestureDetector(
        onTap: () async {
          setState(() => _selectedDateFilter = key);

          if (key == DateFilter.day) {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );

            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          }

          if (key == DateFilter.month) {
            // final now = DateTime.now();
            final pickedMonth = await showMonthPicker(
              context: context,
              initialDate: _selectedDate,
            );
            if (pickedMonth != null) {
              setState(() {
                _selectedDate = DateTime(
                  pickedMonth.year,
                  pickedMonth.month,
                  1,
                );
              });
            }
            // setState(() => _selectedDate = DateTime(now.year, now.month, 1));
          }

          if (key == DateFilter.year) {
            // final now = DateTime.now();
            // setState(() => _selectedDate = DateTime(now.year, 1, 1));

            final pickedYear = await showDialog<int>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Select Year"),
                content: SizedBox(
                  width: 350,
                  height: 300,
                  child: YearPicker(
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _selectedDate,
                    selectedDate: _selectedDate,
                    onChanged: (date) {
                      Navigator.pop(ctx, date.year);
                    },
                  ),
                ),
              ),
            );

            if (pickedYear != null) {
              setState(() {
                _selectedDate = DateTime(
                  pickedYear,
                  _selectedDate.month,
                  _selectedDate.day,
                );
              });
              _applyFilter();
            }
          }

          _applyFilter(); // refresh
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 90,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.redAccent : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.brown.shade300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              getLabel(key),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.brown,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // ← CENTER FIX
        children: DateFilter.values.map(buildChip).toList(),
      ),
    );
  }

  Widget _buildAddDrawerButton() {
    final bool isCancel = showForm;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          icon: Icon(
            isCancel ? Icons.close_rounded : Icons.add_rounded,
            size: 26,
            color: Colors.white,
          ),
          label: Text(
            isCancel ? 'Cancel' : 'Add Drawing  ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCancel
                ? const Color(0xFFE57373)
                : const Color(0xFF26A69A),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: _submitting
              ? null
              : () {
                  setState(() => showForm = !showForm);
                },
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final bool disabled = _submitting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade200.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Drawing Details",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(
                  labelText: "Type",
                  prefixIcon: Icon(
                    Icons.swap_vert_rounded,
                    color: Colors.teal.shade700,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.teal.shade200,
                      width: 1.4,
                    ),
                  ),
                ),
                items: ['IN', 'OUT']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: disabled
                    ? null
                    : (val) => setState(() => type = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                enabled: !disabled,
                decoration: InputDecoration(
                  labelText: "Reason",
                  prefixIcon: Icon(
                    Icons.description_rounded,
                    color: Colors.teal.shade700,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.teal.shade200,
                      width: 1.4,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                enabled: !disabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: Icon(
                    Icons.currency_rupee_rounded,
                    color: Colors.teal.shade700,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.teal.shade200,
                      width: 1.4,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onEditingComplete: disabled ? null : createDrawer,
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: _submitting
                        ? [Colors.grey, Colors.grey] // During submit
                        : (type == "OUT" && balance <= 0)
                        ? [Colors.grey, Colors.grey] // Disabled OUT
                        : [
                            Colors.teal.shade600,
                            Colors.teal.shade400,
                          ], // Enabled
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.shade300.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : (type == "OUT" && balance <= 0)
                      ? null
                      : createDrawer,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : (type == "OUT" && balance <= 0)
                      ? const Text(
                          "No Balance",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 17,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.teal.shade200, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade100.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  // color: isPositive ? Colors.green : Colors.red,
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                Text(
                  "Total Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    // color: isPositive
                    //     ? Colors.green.shade900
                    //     : Colors.red.shade900
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.arrow_forward, color: Colors.green, size: 26),
                const SizedBox(width: 10),
                const Text(
                  "IN",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  "₹ ${totalIN.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.red, size: 26),
                const SizedBox(width: 10),
                const Text(
                  "OUT",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  "₹ ${totalOUT.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.teal.shade200),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.teal,
                  size: 26,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Cash On Hand",

                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  "₹ ${balance.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 20), // adjust space from top
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: Text(error, style: const TextStyle(color: Colors.red)),
          trailing: TextButton(
            onPressed: fetchDrawers,
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}
