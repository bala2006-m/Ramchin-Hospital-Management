import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/payment_service.dart';
import '../Page/PaymentPage.dart';

class FeesQueuePage extends StatefulWidget {
  const FeesQueuePage({super.key});

  @override
  State<FeesQueuePage> createState() => _FeesQueuePageState();
}

class _FeesQueuePageState extends State<FeesQueuePage> {
  late Future<List<dynamic>> _feesFuture;

  List<dynamic> _allFees = []; // All payment data
  List<dynamic> _queueFees = []; // Pending fees
  List<dynamic> _historyFees = []; // Paid fees after filter/search
  List<dynamic> _cancelledFees = [];
  String cancelledFilter = 'Today'; // Today | Before
  String queueFilter = 'Today'; // Today | Before

  int _currentIndex = 0; // 0 = Queue, 1 = History

  // History search/filter
  TextEditingController searchController = TextEditingController();
  String historyFilter = 'Today'; // Default to Today

  final DateFormat dateFormat = DateFormat(
    'yyyy-MM-dd hh:mm a',
  ); // Your date format

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  void _loadFees() {
    _feesFuture = PaymentService().getAllPendingFees().then((list) {
      // Normalize status
      List<dynamic> normalized = list.map((e) {
        e["status"] = e["status"].toString().toLowerCase();
        return e;
      }).toList();

      _allFees = normalized;

      // Separate queue and paid
      _queueFees = _allFees.where((e) => e["status"] == "pending").toList();
      _cancelledFees = _allFees
          .where((e) => e["status"] == "cancelled")
          .toList();

      _applyCancelledFilter();
      _applyQueueFilter();

      _applyHistoryFilter(); // Updates _historyFees

      return _currentIndex == 0 ? _queueFees : _historyFees;
    });
    setState(() {});
  }

  void _applyHistoryFilter() {
    List<dynamic> filtered = _allFees
        .where((e) => e["status"] == "paid")
        .toList();
    final now = DateTime.now();

    // Apply Today / Month / Overall filters
    if (historyFilter == 'Today') {
      filtered = filtered.where((e) {
        try {
          final date = dateFormat.parse(e['updatedAt']);
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        } catch (_) {
          return false;
        }
      }).toList();
    } else if (historyFilter == 'Month') {
      filtered = filtered.where((e) {
        try {
          final date = dateFormat.parse(e['updatedAt']);
          return date.year == now.year && date.month == now.month;
        } catch (_) {
          return false;
        }
      }).toList();
    } // Overall = no filter

    // Apply search filter
    final search = searchController.text.toLowerCase();
    if (search.isNotEmpty) {
      filtered = filtered.where((e) {
        final patient = e['Patient'] ?? {};
        final name = (patient['name'] ?? '').toString().toLowerCase();
        final userId = (patient['id'] ?? '').toString().toLowerCase();
        return name.contains(search) || userId.contains(search);
      }).toList();
    }

    // Sort latest first
    filtered.sort((a, b) {
      try {
        final dateA = dateFormat.parse(a['updatedAt']);
        final dateB = dateFormat.parse(b['updatedAt']);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    _historyFees = filtered;
  }

  void _applyQueueFilter() {
    final now = DateTime.now();

    _queueFees = _allFees.where((e) {
      if (e["status"].toString().toLowerCase() != "pending") return false;

      try {
        final date = dateFormat.parse(e['createdAt']);
        if (queueFilter == 'Today') {
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        } else {
          return date.isBefore(DateTime(now.year, now.month, now.day));
        }
      } catch (_) {
        return false;
      }
    }).toList();

    _queueFees.sort((a, b) {
      try {
        return dateFormat
            .parse(a['createdAt'])
            .compareTo(dateFormat.parse(b['createdAt']));
      } catch (_) {
        return 0;
      }
    });
  }

  DateTime? parseAnyDate(dynamic value) {
    if (value == null) return null;

    final str = value.toString().trim();
    if (str.isEmpty) return null;

    // 1️⃣ Try ISO format (2025-12-27 18:06:58.965092)
    try {
      return DateTime.parse(str);
    } catch (_) {}

    // 2️⃣ Try your custom format (2025-12-27 09:25 PM)
    try {
      return DateFormat('yyyy-MM-dd hh:mm a').parse(str);
    } catch (_) {}

    return null;
  }

  void _applyCancelledFilter() {
    final now = DateTime.now();

    List<dynamic> filtered = _allFees.where((e) {
      final status = e["status"]?.toString().toLowerCase().trim();
      if (status != "cancelled") return false;

      final date = parseAnyDate(e['updatedAt']) ?? parseAnyDate(e['createdAt']);
      if (date == null) return false;

      if (cancelledFilter == 'Today') {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } else {
        return date.isBefore(DateTime(now.year, now.month, now.day));
      }
    }).toList();

    // Sort latest first
    filtered.sort((a, b) {
      final dateA =
          parseAnyDate(a['updatedAt']) ?? parseAnyDate(a['createdAt']);
      final dateB =
          parseAnyDate(b['updatedAt']) ?? parseAnyDate(b['createdAt']);
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    setState(() {
      _cancelledFees = filtered;
    });

    print("✅ Cancelled fees count: ${_cancelledFees.length}");
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFBF955E);

    String formatDob(String? dob) {
      if (dob == null || dob.isEmpty) return 'N/A';
      try {
        final date = DateTime.parse(dob);
        return DateFormat('dd-MM-yyyy').format(date);
      } catch (_) {
        return dob;
      }
    }

    String calculateAge(String? dob) {
      if (dob == null || dob.isEmpty) return 'N/A';
      try {
        final date = DateTime.parse(dob);
        final now = DateTime.now();
        int age = now.year - date.year;
        if (now.month < date.month ||
            (now.month == date.month && now.day < date.day)) {
          age--;
        }
        return "$age ";
      } catch (_) {
        return 'N/A';
      }
    }

    return Scaffold(
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
                  Text(
                    _currentIndex == 0 ? "Fees Queue" : "Payment History",
                    style: const TextStyle(
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
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _TopTab(
                    label: 'Today',
                    selected: queueFilter == 'Today',
                    onTap: () {
                      setState(() {
                        queueFilter = 'Today';
                        _applyQueueFilter();
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _TopTab(
                    label: 'Previous',
                    selected: queueFilter == 'Before',
                    onTap: () {
                      setState(() {
                        queueFilter = 'Before';
                        _applyQueueFilter();
                      });
                    },
                  ),
                ],
              ),
            ),

          if (_currentIndex == 1)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      FilterButton(
                        label: 'Today',
                        selected: historyFilter == 'Today',
                        onTap: () {
                          setState(() {
                            historyFilter = 'Today';
                            _applyHistoryFilter();
                          });
                        },
                      ),
                      FilterButton(
                        label: 'Month',
                        selected: historyFilter == 'Month',
                        onTap: () {
                          setState(() {
                            historyFilter = 'Month';
                            _applyHistoryFilter();
                          });
                        },
                      ),
                      FilterButton(
                        label: 'Overall',
                        selected: historyFilter == 'Overall',
                        onTap: () {
                          setState(() {
                            historyFilter = 'Overall';
                            _applyHistoryFilter();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 6.0,
                          ),
                          child: TextField(
                            cursorColor: Color(0xFFBF955E),
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: "Search by Name or User ID",
                              prefixIcon: const Icon(Icons.search),

                              // Rounded border
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),

                              // Focused border prettier
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBF955E),
                                  width: 2,
                                ),
                              ),

                              // Enabled border
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),

                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (_) {
                              setState(() {
                                _applyHistoryFilter();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_currentIndex == 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _TopTab(
                    label: 'Today',
                    selected: cancelledFilter == 'Today',
                    onTap: () {
                      setState(() {
                        cancelledFilter = 'Today';
                        _applyCancelledFilter();
                      });
                    },
                  ),
                  _TopTab(
                    label: 'Before',
                    selected: cancelledFilter == 'Before',
                    onTap: () {
                      setState(() {
                        cancelledFilter = 'Before';
                        _applyCancelledFilter();
                      });
                    },
                  ),
                ],
              ),
            ),

          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _feesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Lottie.asset(
                        'assets/Lottie/error404.json',
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                  );
                } else if (_currentIndex == 1 && _historyFees.isEmpty) {
                  return const Center(
                    child: Text(
                      '📜 No Payment History Available!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                } else if (_currentIndex == 0 && _queueFees.isEmpty) {
                  return const Center(
                    child: Text(
                      '🎉 No Pending Fees!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                } else {
                  //final data = _currentIndex == 0 ? _queueFees : _historyFees;
                  final data = _currentIndex == 0
                      ? _queueFees
                      : _currentIndex == 1
                      ? _historyFees
                      : _cancelledFees;
                  if (data.isEmpty) {
                    return Center(
                      child: Text(
                        _currentIndex == 2
                            ? '❌ No Cancelled Payments!'
                            : 'No Data Available',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final patient = item['Patient'] ?? {};

                      return GestureDetector(
                        onTap: _currentIndex == 2
                            ? null // ❌ Disable tap for Cancelled
                            : () async {
                                // if (_currentIndex == 1) return;

                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FeesPaymentPage(
                                      fee: item,
                                      patient: patient,
                                      index: _currentIndex,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  _loadFees();
                                }
                              },
                        child: Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: themeColor.withValues(alpha: 0.5),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                      horizontal: 16.0,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize
                                          .min, // so column takes minimal vertical space
                                      crossAxisAlignment: CrossAxisAlignment
                                          .center, // left-align text inside
                                      children: [
                                        Text(
                                          item['reason'] ?? 'Unknown Fee',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
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
                                              getString(
                                                item['Consultation']['tokenNo'] ??
                                                    '-',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                //const SizedBox(height: 8),
                                const Divider(thickness: 1),

                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Patient: ${getString(patient['name'])}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'AGE: ${calculateAge(getString(patient['dob']))}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ID: ${getString(patient['id'])}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      'DOB: ${formatDob(getString(patient['dob']))}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Address: ${getString(patient['address']?['Address'])}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                const Divider(thickness: 1),
                                const SizedBox(height: 8),

                                Center(
                                  child: Text(
                                    'Amount: ₹ ${item['amount']?.toStringAsFixed(0) ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFBF955E),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                if (_currentIndex == 1) ...[
                                  Row(
                                    children: [
                                      Center(
                                        child: Text(
                                          '${getFormattedDate(item['updatedAt'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        'Paid',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      SizedBox(width: 5),
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),

      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _currentIndex,
      //   selectedItemColor: themeColor,
      //   unselectedItemColor: Colors.grey,
      //   onTap: (index) {
      //     setState(() {
      //       _currentIndex = index;
      //       _feesFuture = Future.value(index == 0 ? _queueFees : _historyFees);
      //     });
      //   },
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.queue), label: "Queue"),
      //     BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
      //   ],
      // ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: themeColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _feesFuture = Future.value(
              index == 0
                  ? _queueFees
                  : index == 1
                  ? _historyFees
                  : _cancelledFees,
            );
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.queue), label: "Queue"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.cancel), label: "Cancelled"),
        ],
      ),
    );
  }

  static String getString(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value;
    return value.toString();
  }

  static String getFormattedDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateFormat('yyyy-MM-dd hh:mm a').parse(value);
      return DateFormat('dd-MM-yyyy hh:mm a').format(date);
    } catch (_) {
      return value.toString();
    }
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFBF955E);
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? themeColor : Colors.grey.shade200,
        foregroundColor: selected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFBF955E);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? themeColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 32 : 0,
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
