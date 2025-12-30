import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/testing&scanning_service.dart';
import '../Page/LabPage.dart';

class LabQueuePage extends StatefulWidget {
  const LabQueuePage({super.key});

  @override
  State<LabQueuePage> createState() => _LabQueuePageState();
}

class _LabQueuePageState extends State<LabQueuePage> {
  late Future<List<dynamic>> futureXRayQueue;
  late Future<List<dynamic>> futureSugarQueue;
  final Color primaryColor = const Color(0xFFBF955E);

  Map<String, List<dynamic>> groupedRecords = {};
  int _selectedTabIndex = 1; // default = Lab Test
  int sugarCount = 0;
  int labCount = 0;
  int testedCount = 0;

  @override
  void initState() {
    super.initState();
    futureXRayQueue = TestingScanningService().getAllTestingAndScanning(
      'Tests',
    );
    futureSugarQueue = ConsultationService().getAllSugarConsultation();
  }

  void _groupRecordsByPatient(List<dynamic> records) {
    groupedRecords.clear();
    for (var record in records) {
      String status = (record['status'] ?? '').toString().toUpperCase();
      String queueStatus = (record['queueStatus'] ?? '')
          .toString()
          .toUpperCase();

      // Include only relevant records
      if (status == 'PENDING' ||
          queueStatus == 'PENDING' ||
          queueStatus == 'COMPLETED') {
        String patientId =
            record['Patient']?['id']?.toString() ??
            record['patient_Id']?.toString() ??
            'unknown';
        if (!groupedRecords.containsKey(patientId)) {
          groupedRecords[patientId] = [];
        }
        groupedRecords[patientId]!.add(record);
      }
    }
  }

  Map<String, List<dynamic>> _getFilteredRecords() {
    if (_selectedTabIndex == 2) {
      // TESTED TAB → only completed
      return Map.fromEntries(
        groupedRecords.entries
            .map((entry) {
              final completedTests = entry.value.where((test) {
                return (test['queueStatus'] ?? '').toString().toUpperCase() ==
                    'COMPLETED';
              }).toList();

              return MapEntry(entry.key, completedTests);
            })
            .where((entry) => entry.value.isNotEmpty),
      );
    }

    // LAB TEST TAB → pending / normal queue
    if (_selectedTabIndex == 1) {
      return Map.fromEntries(
        groupedRecords.entries
            .map((entry) {
              final pendingTests = entry.value.where((test) {
                final qs = (test['queueStatus'] ?? '').toString().toUpperCase();
                return qs == 'PENDING';
              }).toList();

              return MapEntry(entry.key, pendingTests);
            })
            .where((entry) => entry.value.isNotEmpty),
      );
    }

    // SUGAR TEST TAB (no backend change yet)
    return groupedRecords;
  }

  Color _genderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Colors.lightBlue.shade400;
      case 'female':
        return Colors.pink.shade300;
      default:
        return Colors.orange.shade400;
    }
  }

  IconData _genderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('allCon $futureSugarQueue');
    print('selected index $_selectedTabIndex');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
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
                    "Lab Test Queue",
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
      ),
      body: _selectedTabIndex == 0 ? _buildSugarQueue() : _buildLabQueue(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bloodtype),
            label: 'Sugar Test',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.science), label: 'Lab Test'),
          BottomNavigationBarItem(icon: Icon(Icons.verified), label: 'Tested'),
        ],
      ),
    );
  }

  Widget _buildLabQueue() {
    return FutureBuilder<List<dynamic>>(
      future: futureXRayQueue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Lottie.asset(
              'assets/Lottie/error404.json',
              width: 280,
              height: 280,
            ),
          );
        }

        final records = snapshot.data ?? [];
        _groupRecordsByPatient(records);
        final filteredRecords = _getFilteredRecords();

        // Compute counts dynamically
        final int pendingCount = groupedRecords.values
            .expand((e) => e)
            .where(
              (e) =>
                  (e['queueStatus'] ?? '').toString().toUpperCase() ==
                  'PENDING',
            )
            .length;

        final int completedCount = groupedRecords.values
            .expand((e) => e)
            .where(
              (e) =>
                  (e['queueStatus'] ?? '').toString().toUpperCase() ==
                  'COMPLETED',
            )
            .length;

        return Column(
          children: [
            // Header with waiting count
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryColor, width: 2),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    _selectedTabIndex == 1
                        ? "Lab Test Patients ( $pendingCount )"
                        : "Tested Patients ( $completedCount )",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),

            // If empty
            if (filteredRecords.isEmpty)
              Expanded(child: _emptyView("No Lab Test patients in queue"))
            else
              Expanded(
                child: RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () async {
                    setState(() {
                      futureXRayQueue = TestingScanningService()
                          .getAllTestingAndScanning('Tests');
                    });
                    await futureXRayQueue;
                  },
                  child: _buildPatientList(filteredRecords),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPatientList(Map<String, List<dynamic>> records) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        String patientId = records.keys.elementAt(index);
        List<dynamic> tests = records[patientId]!;

        final patient = tests.first['Patient'] ?? {};
        final gender = (patient['gender'] ?? 'other').toString();

        return PatientTestCard(
          patient: patient,
          tests: tests,
          genderColor: _genderColor(gender),
          genderIcon: _genderIcon(gender),
          onRefresh: () {
            setState(() {
              futureXRayQueue = TestingScanningService()
                  .getAllTestingAndScanning('Tests');
            });
          },
        );
      },
    );
  }

  Widget _buildSugarQueue() {
    print('work $futureSugarQueue');

    return FutureBuilder<List<dynamic>>(
      future: futureSugarQueue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _emptyView("Failed to load sugar tests");
        }

        final records = snapshot.data ?? [];
        print('recordss $records');

        final sugarRecords = records.where((item) {
          print('itemss $item');
          return item['paymentStatus'] == true &&
              item['symptoms'] == false &&
              item['status'] == 'PENDING' &&
              item['sugerTestQueue'] == true &&
              item['sugerTest'] == true;
        }).toList();
        for (var r in records) {
          debugPrint(
            'SugarCheck → id:${r['id']} '
            'pay:${r['paymentStatus']} '
            'sym:${r['symptoms']} '
            'stat:${r['status']} '
            'queue:${r['sugerTestQueue']} '
            'test:${r['sugerTest']}',
          );
        }

        final int sugarCount = sugarRecords.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryColor, width: 2),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    "Sugar Test Patients ( $sugarCount )",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
            if (sugarRecords.isEmpty)
              Expanded(child: _emptyView("No Sugar Test patients"))
            else
              Expanded(
                child: RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () async {
                    setState(() {
                      futureSugarQueue = ConsultationService()
                          .getAllSugarConsultation();
                    });
                    await futureSugarQueue;
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: sugarRecords.length,
                    itemBuilder: (context, index) {
                      final record = sugarRecords[index];
                      final patient = record['Patient'] ?? {};
                      final gender = (patient['gender'] ?? 'other').toString();
                      final tokenNo =
                          (record['tokenNo'] == null || record['tokenNo'] == 0)
                          ? '-'
                          : record['tokenNo'].toString();

                      return _SugarPatientCard(
                        patient: patient,
                        consultationId: record['id'].toString(),
                        tokenNo: tokenNo,
                        genderColor: _genderColor(gender),
                        genderIcon: _genderIcon(gender),
                        onRefresh: () {
                          setState(() {
                            futureSugarQueue = ConsultationService()
                                .getAllSugarConsultation();
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _emptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/Lottie/NoData.json', width: 250),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class PatientTestCard extends StatefulWidget {
  final Map<String, dynamic> patient;
  final List<dynamic> tests;
  final Color genderColor;
  final IconData genderIcon;
  final VoidCallback onRefresh;

  const PatientTestCard({
    Key? key,
    required this.patient,
    required this.tests,
    required this.genderColor,
    required this.genderIcon,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<PatientTestCard> createState() => _PatientTestCardState();
}

class _PatientTestCardState extends State<PatientTestCard> {
  final Set<int> _completedTestIds = {};

  bool get _isAllCompleted {
    if (widget.tests.isEmpty) return false;
    return widget.tests.every(
      (test) =>
          (test['queueStatus'] ?? '').toString().toUpperCase() == 'COMPLETED',
    );
  }

  @override
  Widget build(BuildContext context) {
    print(widget.patient);
    String patientName = widget.patient['name'] ?? 'Unknown';
    String patientId = widget.patient['id']?.toString() ?? 'N/A';

    String patientPhone = widget.patient['phone']?.toString() ?? 'N/A';
    String patientAddress = 'N/A';

    if (widget.patient['address'] != null) {
      if (widget.patient['address'] is Map) {
        patientAddress = widget.patient['address']['Address'] ?? 'N/A';
      } else if (widget.patient['address'] is String) {
        patientAddress = widget.patient['address'];
      }
    }

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with patient gender icon and name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.genderIcon, size: 28, color: widget.genderColor),
              const SizedBox(width: 8),
              Text(
                patientName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.genderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            color: Colors.grey.shade400,
            thickness: 1.4,
            indent: 25,
            endIndent: 25,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              children: [
                _infoRow('Patient ID', patientId),
                const SizedBox(height: 6),
                _infoRow('Cell No', patientPhone),
                const SizedBox(height: 6),
                _infoRow('Address', patientAddress),
              ],
            ),
          ),
          Divider(
            color: Colors.grey.shade400,
            thickness: 1.4,
            indent: 25,
            endIndent: 25,
          ),

          // Always show all test titles (even if completed)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.tests.length,
            itemBuilder: (context, index) {
              final test = widget.tests[index];
              final testId = test['id'];
              final title = test['title'] ?? 'No Title';
              final queueStatus = (test['queueStatus'] ?? '')
                  .toString()
                  .toLowerCase();

              bool isCompletedLocal =
                  testId != null && _completedTestIds.contains(testId);
              bool isCompletedStatus = queueStatus == 'completed';

              Widget trailingIcon;
              if (isCompletedStatus) {
                trailingIcon = const Icon(Icons.done_all, color: Colors.blue);
              } else if (isCompletedLocal) {
                trailingIcon = const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                );
              } else {
                trailingIcon = const Icon(Icons.chevron_right);
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  trailing: trailingIcon,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LabPage(
                          allTests: widget.tests
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList(),
                          currentIndex: index,
                          queueStaus: queueStatus.toUpperCase(),
                          mode: 0, // individual test click
                        ),
                      ),
                    );
                    if (result == true && testId != null) {
                      setState(() {
                        _completedTestIds.add(testId);
                      });
                      widget.onRefresh();
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );

    // Full card click if all tests completed
    return GestureDetector(
      onTap: _isAllCompleted
          ? () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LabPage(
                    allTests: widget.tests
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList(),
                    currentIndex: 0,
                    queueStaus: 'COMPLETED',
                    mode: 1, // full card click
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  // futureXRayQueue = TestingScanningService()
                  //     .getAllTestingAndScanning('Tests');
                  widget.onRefresh();
                });
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.genderColor.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black45.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: cardContent,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '$label :',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SugarPatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final String consultationId;
  final String tokenNo;
  final Color genderColor;

  final IconData genderIcon;
  final VoidCallback onRefresh;

  const _SugarPatientCard({
    required this.patient,
    required this.consultationId,
    required this.genderColor,
    required this.genderIcon,
    required this.onRefresh,
    required this.tokenNo,
  });

  @override
  Widget build(BuildContext context) {
    final String name = patient['name'] ?? 'Unknown';
    final String id = patient['id']?.toString() ?? 'N/A';
    String phone = 'N/A';
    if (patient['phone'] is Map) {
      phone = patient['phone']['mobile']?.toString() ?? 'N/A';
    } else if (patient['phone'] is String) {
      phone = patient['phone'];
    }

    String address = 'N/A';
    if (patient['address'] is Map) {
      address = patient['address']['Address'] ?? 'N/A';
    } else if (patient['address'] is String) {
      address = patient['address'];
    }

    return GestureDetector(
      onTap: () => _openSugarDialog(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: genderColor),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              //crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
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
            Row(
              children: [
                Icon(genderIcon, color: genderColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: genderColor,
                    ),
                  ),
                ),
                const Chip(
                  label: Text("Sugar Test"),
                  backgroundColor: Color(0xFFE8F5E9),
                ),
              ],
            ),

            const SizedBox(height: 10),
            _infoRow("Patient ID", id),
            _infoRow("Phone", phone),
            _infoRow("Address", address),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  /// 👇 Dialog
  void _openSugarDialog(BuildContext context) {
    final TextEditingController sugarController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bool isValidInput = sugarController.text.trim().isNotEmpty;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      children: [
                        Icon(Icons.bloodtype, color: genderColor, size: 26),
                        const SizedBox(width: 8),
                        const Text(
                          "Sugar Test",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "Enter Sugar Level (mg/dL)",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),

                    const SizedBox(height: 12),

                    /// Input Field
                    TextField(
                      controller: sugarController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "e.g. 110",
                        prefixIcon: const Icon(Icons.monitor_heart_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isValidInput
                                  ? genderColor
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: (!isValidInput || isLoading)
                                ? null
                                : () async {
                                    setState(() => isLoading = true);

                                    await ConsultationService()
                                        .updateConsultation(
                                          int.parse(consultationId),
                                          {
                                            "sugerTestQueue": false,
                                            "sugar": sugarController.text
                                                .trim(),
                                          },
                                        );

                                    Navigator.pop(context);
                                    onRefresh();
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
                                : const Text(
                                    "Submit",
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
