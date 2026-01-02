import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/Scan_Test_Get-Service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/socket_service.dart';
import '../../../../utils/utils.dart';

class TestingPage extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final List<Map<String, dynamic>> testOptionName;
  final String role;

  const TestingPage({
    super.key,
    required this.consultation,
    required this.testOptionName,
    required this.role,
  });

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  final Color primaryColor = const Color(0xFFBF955E);
  final socketService = SocketService();

  bool _isSubmitting = false;
  bool _isLoading = true;
  bool scanningTesting = false;

  String searchQuery = "";

  String? _dateTime;
  int _expandedIndex = -1;
  final Map<String, TextEditingController> _descControllers = {};

  final Map<String, Map<String, dynamic>> savedTests = {};
  final Map<String, bool> showAllMap = {};

  List<Map<String, dynamic>> tests = [];
  final ScanTestGetService _testScanService = ScanTestGetService();

  // final TestingScanningService _CurrentTestingScanningService =
  //     TestingScanningService();
  final TextEditingController descController = TextEditingController();
  List<Map<String, dynamic>> submittedTests = [];
  Map<String, List<Map<String, dynamic>>> mergedPaymentGroups = {};

  @override
  void initState() {
    super.initState();
    _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final fetchedTests = await _testScanService.fetchTests('TEST');

      // final currentSubmitTest =
      //     await _CurrentTestingScanningService.getAllTestingAndScanningData();

      setState(() {
        tests = fetchedTests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to fetch tests: $e')));
      }
    }
  }

  // FILTERED LIST
  List<Map<String, dynamic>> get filteredTests {
    if (searchQuery.trim().isEmpty) return tests;

    return tests
        .where(
          (t) => t['title'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  int _calculateTotalAmount(
    Map<String, dynamic> test,
    Set<String> selectedOptions,
  ) {
    final List<dynamic> options = test['options'] ?? [];
    int total = 0;
    for (var optName in selectedOptions) {
      for (var option in options) {
        if (option['optionName'] == optName) {
          total += option['price'] as int? ?? 0;
          break;
        }
      }
    }
    return total;
  }

  Future<void> _submitAllTests() async {
    if (savedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No tests selected."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final doctorId = widget.role == 'doctor'
          ? prefs.getString('userId') ?? ''
          : prefs.getString('assistantDoctorId') ?? '';
      final hospitalId = widget.consultation['hospital_Id'];
      final patientId = widget.consultation['patient_Id'];
      final consultationId = widget.consultation['id'];
      if (consultationId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation ID not found')),
        );
        return;
      }

      for (var entry in savedTests.entries) {
        final testName = entry.key;
        final testData = entry.value;

        final data = {
          "hospital_Id": hospitalId,
          "patient_Id": patientId,
          "doctor_Id": doctorId,
          "staff_Id": [],
          "title": testName,
          "consultation_Id": consultationId,
          "type": 'Tests',
          "scheduleDate": DateTime.now().toIso8601String(),
          "status": "PENDING",
          "paymentStatus": false,
          'reason': testData['description'],
          "result": '',
          "amount": testData['totalAmount'],
          "selectedOptions": testData['options'].toList(),
          "selectedOptionAmounts": testData['selectedOptionsAmount'],
          "createdAt": _dateTime.toString(),
        };

        await http.post(
          Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
      }
      setState(() {
        scanningTesting = true;
      });
      await ConsultationService().updateConsultation(consultationId, {
        'status': 'ONGOING',
        'scanningTesting': scanningTesting,
        // 'medicineTonic': medicineTonicInjection,
        // 'Injection': injection,
        'queueStatus': 'COMPLETED',
        'updatedAt': _dateTime.toString(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('tests submitted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
      setState(() => scanningTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "View Testing",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // SEARCH FIELD
          ],
        ),
      ),

      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : filteredTests.isEmpty
          ? Center(
              child: Text(
                "No tests found",
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: "Search test name. . .",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (savedTests.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "🧪 Selected Test Summary",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            ...savedTests.entries.map((entry) {
                              final String testName = entry.key;
                              final Set<String> options =
                                  (entry.value['options'] ?? <String>{})
                                      as Set<String>;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Test Name
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            testName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          Text(
                                            "${options.length} Selected",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Options List
                                      ...options.map(
                                        (opt) => Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                            top: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 6,
                                                color: primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                opt,
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  Column(
                    children: [
                      for (int index = 0; index < filteredTests.length; index++)
                        _buildTestCard(filteredTests[index], index),
                    ],
                  ),

                  SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitAllTests,
        icon: const Icon(Icons.cloud_upload),
        label: const Text("Submit Tests"),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // SizedBox(
  //   height: MediaQuery.of(context).size.height * 0.6,
  //   child: ListView.builder(
  //     itemCount: filteredTests.length,
  //     padding: const EdgeInsets.symmetric(horizontal: 8),
  //     itemBuilder: (context, index) {
  //       return _buildTestCard(filteredTests[index], index);
  //     },
  //   ),
  // ),
  Widget _buildTestCard(Map<String, dynamic> test, int index) {
    final String testName = test['title'];
    final bool isExpanded = _expandedIndex == index;
    final List<dynamic> options = test['options'] ?? [];
    final Set<String> selectedOptions =
        (savedTests[testName]?['options'] ?? <String>{}) as Set<String>;

    // final descController = TextEditingController(
    //   text: savedTests[testName]?['description'] ?? '',
    // );
    _descControllers.putIfAbsent(
      testName,
      () => TextEditingController(
        text: savedTests[testName]?['description'] ?? '',
      ),
    );

    final descController = _descControllers[testName]!;

    final Map<String, dynamic> existingResult = (widget.testOptionName)
        .firstWhere(
          (e) => e['title'].toString().toLowerCase() == testName.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );

    final List<dynamic> completedResults =
        (existingResult['results'] ?? []) as List<dynamic>;
    final bool anyCompleted = completedResults.isNotEmpty;

    final bool showAll = showAllMap[testName] ?? false;
    final List<dynamic> displayedOptions = showAll
        ? options
        : options.take(4).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      // color: anyCompleted ? Colors.green.shade100 : Colors.white,
      child: ExpansionTile(
        key: ValueKey('test_$index'),
        leading: anyCompleted
            ? CircleAvatar(
                backgroundColor: Colors.green.withValues(alpha: 0.15),
                child: Icon(Icons.science, color: Colors.green),
              )
            : CircleAvatar(
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child: Icon(Icons.science, color: primaryColor),
              ),
        title: Center(
          child: Text(
            testName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: anyCompleted ? Colors.green : Colors.black87,
            ),
          ),
        ),

        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _expandedIndex = expanded ? index : -1);
        },

        children: [
          Divider(
            thickness: 1.5,
            color: primaryColor.withValues(alpha: 0.6),
            indent: 30,
            endIndent: 30,
          ),

          // OPTIONS
          ...displayedOptions.map((opt) {
            //final String name = opt['name'] ?? '';
            final String name = opt['optionName'] ?? '';

            final int price = opt['price'];

            final resultMatch = (completedResults.cast<Map<String, dynamic>>())
                .firstWhere(
                  (r) =>
                      r['Test']?.toString().toLowerCase() == name.toLowerCase(),

                  orElse: () => <String, dynamic>{},
                );

            final bool isCompleted = resultMatch.isNotEmpty;
            final selected = selectedOptions.contains(name);

            return AbsorbPointer(
              absorbing: isCompleted,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.08)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : primaryColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),

                // COMPLETED VIEW
                child: isCompleted
                    ? ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Result: ${resultMatch['Result'] ?? '-'} ${resultMatch['Unit'] ?? ''}\n"
                              "Range: ${resultMatch['Range'] ?? ''}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      )
                    // NORMAL CHECKBOX VIEW
                    : CheckboxListTile(
                        value: selected,
                        // onChanged: (v) {
                        //   setState(() {
                        //     final mutable = Set<String>.from(selectedOptions);
                        //     if (v == true) {
                        //       mutable.add(name);
                        //     } else {
                        //       mutable.remove(name);
                        //     }
                        //
                        //     // savedTests[testName] = {
                        //     //   'options': mutable,
                        //     //   'description':
                        //     //       savedTests[testName]?['description'] ?? '',
                        //     //   'totalAmount': _calculateTotalAmount(
                        //     //     test,
                        //     //     mutable,
                        //     //   ),
                        //     // };
                        //     if (mutable.isEmpty) {
                        //       savedTests.remove(
                        //         testName,
                        //       ); // ⬅ remove completely if empty
                        //     } else {
                        //       savedTests[testName] = {
                        //         'options': mutable,
                        //         'description':
                        //             savedTests[testName]?['description'] ?? '',
                        //         'totalAmount': _calculateTotalAmount(
                        //           test,
                        //           mutable,
                        //         ),
                        //       };
                        //     }
                        //   });
                        // },
                        onChanged: (v) {
                          setState(() {
                            // Always initialize safely
                            final Map<String, int> optionAmountMap =
                                savedTests[testName]?['selectedOptionsAmount'] !=
                                    null
                                ? Map<String, int>.from(
                                    savedTests[testName]!['selectedOptionsAmount'],
                                  )
                                : <String, int>{};

                            if (v == true) {
                              optionAmountMap[name] = price;
                            } else {
                              optionAmountMap.remove(name);
                            }

                            if (optionAmountMap.isEmpty) {
                              savedTests.remove(testName);
                            } else {
                              savedTests[testName] = {
                                'options': optionAmountMap.keys.toSet(),
                                'selectedOptionsAmount': optionAmountMap,
                                'description':
                                    savedTests[testName]?['description'] ?? '',
                                'totalAmount': optionAmountMap.values.fold<int>(
                                  0,
                                  (a, b) => a + b,
                                ),
                              };
                            }
                          });
                        },

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        activeColor: primaryColor,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              "₹ $price",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          }),

          if (options.length > 4)
            TextButton(
              child: Text(
                showAll ? "Show Less" : "Show All",
                style: TextStyle(color: primaryColor),
              ),
              onPressed: () => setState(() => showAllMap[testName] = !showAll),
            ),

          // DESCRIPTION FIELD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description / Notes',
                labelStyle: TextStyle(color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
              maxLines: 2,
              onChanged: (value) {
                // savedTests[testName] = {
                //   'options': savedTests[testName]?['options'] ?? <String>{},
                //   'description': value,
                //   'totalAmount': savedTests[testName]?['totalAmount'] ?? 0,
                // };
                setState(() {
                  final existing = savedTests[testName] ?? {};

                  savedTests[testName] = {
                    'options': existing['options'] ?? selectedOptions,
                    'selectedOptionsAmount':
                        existing['selectedOptionsAmount'] ?? <String, int>{},
                    'description': value,
                    'totalAmount':
                        existing['totalAmount'] ??
                        _calculateTotalAmount(test, selectedOptions),
                  };
                });
              },
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

//import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import '../../../../Pages/NotificationsPage.dart';
// import '../../../../Services/Scan_Test_Get-Service.dart';
// import '../../../../Services/consultation_service.dart';
// import '../../../../Services/socket_service.dart';
// import '../../../../Services/testing&scanning_service.dart';
// import '../../../../utils/utils.dart';
// import 'DrOpDashboard/DrOutPatientQueuePage.dart';
//
// class TestingPage extends StatefulWidget {
//   final Map<String, dynamic> consultation;
//   final List<Map<String, dynamic>> testOptionName;
//
//   const TestingPage({
//     super.key,
//     required this.consultation,
//     required this.testOptionName,
//   });
//
//   @override
//   State<TestingPage> createState() => _TestingPageState();
// }
//
// class _TestingPageState extends State<TestingPage> {
//   final Color primaryColor = const Color(0xFFBF955E);
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//   final socketService = SocketService();
//
//   bool _isSubmitting = false;
//   bool _isLoading = true;
//   bool scanningTesting = false;
//
//   String searchQuery = "";
//
//   String? _dateTime;
//   int _expandedIndex = -1;
//
//   final Map<String, Map<String, dynamic>> savedTests = {};
//   final Map<String, bool> showAllMap = {};
//
//   List<Map<String, dynamic>> tests = [];
//   final ScanTestGetService _testScanService = ScanTestGetService();
//   final TestingScanningService _CurrentTestingScanningService =
//       TestingScanningService();
//   final TextEditingController descController = TextEditingController();
//   List<Map<String, dynamic>> submittedTests = [];
//   Map<String, List<Map<String, dynamic>>> mergedPaymentGroups = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
//     _loadTests();
//   }
//
//   Future<void> _loadTests() async {
//     try {
//       final fetchedTests = await _testScanService.fetchTests('TEST');
//
//       final currentSubmitTest =
//           await _CurrentTestingScanningService.getAllTestingAndScanningData();
//
//       submittedTests = (currentSubmitTest ?? [])
//           .cast<Map<String, dynamic>>() // FIX TYPE
//           .where(
//             (t) =>
//                 // t['type'] == 'Tests' &&
//                 // t['status'] == 'PENDING' &&
//                 t['patient_Id'] == widget.consultation['patient_Id'] &&
//                 t['consultation_Id'] == widget.consultation['id'],
//           )
//           .toList();
//
//       mergedPaymentGroups = {};
//       for (var test in submittedTests) {
//         String pid = test["payment_Id"].toString();
//
//         if (!mergedPaymentGroups.containsKey(pid)) {
//           mergedPaymentGroups[pid] = [];
//         }
//         mergedPaymentGroups[pid]!.add(test);
//       }
//
//       setState(() {
//         tests = fetchedTests;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to fetch tests: $e')));
//     }
//   }
//
//   Map<String, Map<String, dynamic>> _buildBackendSummary() {
//     Map<String, Map<String, dynamic>> summary = {};
//
//     mergedPaymentGroups.forEach((pid, group) {
//       for (var test in group) {
//         final title = test["title"];
//         final List<dynamic> opts = test["selectedOptions"] ?? [];
//
//         summary[title] = {
//           "options": opts.toSet(),
//           "description": test["reason"] ?? "",
//         };
//       }
//     });
//
//     return summary;
//   }
//
//   // FILTERED LIST
//   List<Map<String, dynamic>> get filteredTests {
//     if (searchQuery.trim().isEmpty) return tests;
//
//     return tests
//         .where(
//           (t) => t['title'].toString().toLowerCase().contains(
//             searchQuery.toLowerCase(),
//           ),
//         )
//         .toList();
//   }
//
//   int _calculateTotalAmount(
//     Map<String, dynamic> test,
//     Set<String> selectedOptions,
//   ) {
//     final List<dynamic> options = test['options'] ?? [];
//     int total = 0;
//     for (var optName in selectedOptions) {
//       for (var option in options) {
//         if (option['name'] == optName) {
//           total += option['price'] as int? ?? 0;
//           break;
//         }
//       }
//     }
//     return total;
//   }
//
//   Future<void> _submitAllTests() async {
//     if (savedTests.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("No tests selected."),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isSubmitting = true);
//
//     try {
//       final doctorId = await secureStorage.read(key: 'userId') ?? '';
//       final hospitalId = widget.consultation['hospital_Id'];
//       final patientId = widget.consultation['patient_Id'];
//       final consultationId = widget.consultation['id'];
//       if (consultationId == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Consultation ID not found')),
//         );
//         return;
//       }
//
//       for (var entry in savedTests.entries) {
//         final testName = entry.key;
//         final testData = entry.value;
//
//         final data = {
//           "hospital_Id": hospitalId,
//           "patient_Id": patientId,
//           "doctor_Id": doctorId,
//           "staff_Id": [],
//           "title": testName,
//           "consultation_Id": consultationId,
//           "type": 'Tests',
//           "scheduleDate": DateTime.now().toIso8601String(),
//           "status": "PENDING",
//           "paymentStatus": false,
//           'reason': descController.text.trim(),
//           "result": '',
//           "amount": testData['totalAmount'],
//           "selectedOptions": testData['options'].toList(),
//           "createdAt": _dateTime.toString(),
//         };
//
//         await http.post(
//           Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode(data),
//         );
//       }
//       setState(() {
//         scanningTesting = true;
//       });
//       final consultation = await ConsultationService().updateConsultation(
//         consultationId,
//         {
//           'status': 'ONGOING',
//           'scanningTesting': scanningTesting,
//           // 'medicineTonic': medicineTonicInjection,
//           // 'Injection': injection,
//           'queueStatus': 'COMPLETED',
//           'updatedAt': _dateTime.toString(),
//         },
//       );
//       Navigator.pop(context, true);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('tests submitted!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
//       );
//     } finally {
//       setState(() => _isSubmitting = false);
//       setState(() => scanningTesting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(140),
//         child: Column(
//           children: [
//             Container(
//               height: 100,
//               decoration: BoxDecoration(
//                 color: primaryColor,
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(12),
//                   bottomRight: Radius.circular(12),
//                 ),
//               ),
//               child: SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(
//                           Icons.arrow_back_ios,
//                           color: Colors.white,
//                         ),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       const Text(
//                         "View Testing",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(
//                           Icons.notifications,
//                           color: Colors.white,
//                         ),
//                         onPressed: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const NotificationPage(),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             // SUMMARY CARD (NAME + SELECTED OPTIONS ONLY)
//
//             // SEARCH FIELD
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: TextField(
//                 onChanged: (value) {
//                   setState(() => searchQuery = value);
//                 },
//                 decoration: InputDecoration(
//                   hintText: "Search test name. . .",
//                   prefixIcon: const Icon(Icons.search),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 5),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//
//       body: _isSubmitting
//           ? const Center(child: CircularProgressIndicator())
//           : filteredTests.isEmpty
//           ? Center(
//               child: Text(
//                 "No tests found",
//                 style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
//               ),
//             )
//           : SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (savedTests.isNotEmpty || mergedPaymentGroups.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 10,
//                       ),
//                       child: Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                             color: primaryColor.withOpacity(0.4),
//                             width: 1,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black12,
//                               blurRadius: 8,
//                               offset: Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Center(
//                               child: Text(
//                                 "🧪 Selected Test Summary",
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: primaryColor,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//
//                             // 🔥 BUILD SUMMARY SOURCE HERE (VALID AREA)
//                             Builder(
//                               builder: (_) {
//                                 final summarySource = savedTests.isNotEmpty
//                                     ? savedTests
//                                     : _buildBackendSummary();
//
//                                 return Column(
//                                   children: summarySource.entries.map((entry) {
//                                     final String testName = entry.key;
//                                     final Set<String> options =
//                                         Set<String>.from(
//                                           entry.value['options'] ?? [],
//                                         );
//
//                                     return Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 8,
//                                       ),
//                                       child: Container(
//                                         padding: const EdgeInsets.all(12),
//                                         decoration: BoxDecoration(
//                                           color: primaryColor.withOpacity(0.05),
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             // 🔹 Test Name & Count
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment
//                                                       .spaceBetween,
//                                               children: [
//                                                 Text(
//                                                   testName,
//                                                   style: TextStyle(
//                                                     fontSize: 16,
//                                                     fontWeight: FontWeight.bold,
//                                                     color: primaryColor,
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                   "${options.length} Selected",
//                                                   style: TextStyle(
//                                                     fontSize: 12,
//                                                     color: Colors.black54,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//
//                                             const SizedBox(height: 6),
//
//                                             // 🔹 Options List
//                                             ...options.map(
//                                               (opt) => Padding(
//                                                 padding: const EdgeInsets.only(
//                                                   left: 8,
//                                                   top: 4,
//                                                 ),
//                                                 child: Row(
//                                                   children: [
//                                                     Icon(
//                                                       Icons.circle,
//                                                       size: 6,
//                                                       color: primaryColor,
//                                                     ),
//                                                     const SizedBox(width: 8),
//                                                     Text(
//                                                       opt,
//                                                       style: TextStyle(
//                                                         fontSize: 14,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   }).toList(),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                   Container(
//                     child: Column(
//                       children: [
//                         for (
//                           int index = 0;
//                           index < filteredTests.length;
//                           index++
//                         )
//                           _buildTestCard(filteredTests[index], index),
//                       ],
//                     ),
//                   ),
//
//                   SizedBox(height: 80),
//                 ],
//               ),
//             ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       floatingActionButton: ElevatedButton.icon(
//         onPressed: _isSubmitting ? null : _submitAllTests,
//         icon: const Icon(Icons.cloud_upload),
//         label: const Text("Submit Tests"),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primaryColor,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // SizedBox(
//   //   height: MediaQuery.of(context).size.height * 0.6,
//   //   child: ListView.builder(
//   //     itemCount: filteredTests.length,
//   //     padding: const EdgeInsets.symmetric(horizontal: 8),
//   //     itemBuilder: (context, index) {
//   //       return _buildTestCard(filteredTests[index], index);
//   //     },
//   //   ),
//   // ),
//   Widget _buildTestCard(Map<String, dynamic> test, int index) {
//     final String testName = test['title'];
//     final bool isExpanded = _expandedIndex == index;
//     final List<dynamic> options = test['options'] ?? [];
//     final Set<String> selectedOptions =
//         (savedTests[testName]?['options'] ?? <String>{}) as Set<String>;
//
//     final descController = TextEditingController(
//       text: savedTests[testName]?['description'] ?? '',
//     );
//
//     final Map<String, dynamic> existingResult = (widget.testOptionName)
//         .firstWhere(
//           (e) => e['title'].toString().toLowerCase() == testName.toLowerCase(),
//           orElse: () => <String, dynamic>{},
//         );
//
//     final List<dynamic> completedResults =
//         (existingResult['results'] ?? []) as List<dynamic>;
//     final bool anyCompleted = completedResults.isNotEmpty;
//
//     final bool showAll = showAllMap[testName] ?? false;
//     final List<dynamic> displayedOptions = showAll
//         ? options
//         : options.take(4).toList();
//
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       elevation: 5,
//       // color: anyCompleted ? Colors.green.shade100 : Colors.white,
//       child: ExpansionTile(
//         key: ValueKey('test_$index'),
//         leading: anyCompleted
//             ? CircleAvatar(
//                 backgroundColor: Colors.green.withOpacity(0.15),
//                 child: Icon(Icons.science, color: Colors.green),
//               )
//             : CircleAvatar(
//                 backgroundColor: primaryColor.withOpacity(0.15),
//                 child: Icon(Icons.science, color: primaryColor),
//               ),
//         title: Center(
//           child: Text(
//             testName,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//               color: anyCompleted ? Colors.green : Colors.black87,
//             ),
//           ),
//         ),
//
//         initiallyExpanded: isExpanded,
//         onExpansionChanged: (expanded) {
//           setState(() => _expandedIndex = expanded ? index : -1);
//         },
//
//         children: [
//           Divider(
//             thickness: 1.5,
//             color: primaryColor.withOpacity(0.6),
//             indent: 30,
//             endIndent: 30,
//           ),
//
//           // OPTIONS
//           ...displayedOptions.map((opt) {
//             final String name = opt['name'];
//             final int price = opt['price'];
//
//             final resultMatch = (completedResults.cast<Map<String, dynamic>>())
//                 .firstWhere(
//                   (r) =>
//                       r['Test']?.toString()?.toLowerCase() ==
//                       name.toLowerCase(),
//                   orElse: () => <String, dynamic>{},
//                 );
//
//             final bool isCompleted = resultMatch.isNotEmpty;
//             final selected = selectedOptions.contains(name);
//
//             return AbsorbPointer(
//               absorbing: isCompleted,
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: isCompleted
//                       ? Colors.green.withOpacity(0.08)
//                       : Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: isCompleted
//                         ? Colors.green
//                         : primaryColor.withOpacity(0.4),
//                     width: 1,
//                   ),
//                 ),
//
//                 // COMPLETED VIEW
//                 child: isCompleted
//                     ? ListTile(
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 4,
//                         ),
//                         title: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 name,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.green.shade700,
//                                 ),
//                               ),
//                             ),
//                             const Icon(
//                               Icons.check_circle,
//                               color: Colors.green,
//                               size: 20,
//                             ),
//                           ],
//                         ),
//                         subtitle: Padding(
//                           padding: const EdgeInsets.only(top: 6),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.green.withOpacity(0.05),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               "Result: ${resultMatch['Result'] ?? '-'} ${resultMatch['Unit'] ?? ''}\n"
//                               "Range: ${resultMatch['Range'] ?? ''}",
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.black87,
//                                 height: 1.4,
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                     // NORMAL CHECKBOX VIEW
//                     : CheckboxListTile(
//                         value: selected,
//                         onChanged: (v) {
//                           setState(() {
//                             final mutable = Set<String>.from(selectedOptions);
//                             if (v == true) {
//                               mutable.add(name);
//                             } else {
//                               mutable.remove(name);
//                             }
//
//                             // savedTests[testName] = {
//                             //   'options': mutable,
//                             //   'description':
//                             //       savedTests[testName]?['description'] ?? '',
//                             //   'totalAmount': _calculateTotalAmount(
//                             //     test,
//                             //     mutable,
//                             //   ),
//                             // };
//                             if (mutable.isEmpty) {
//                               savedTests.remove(
//                                 testName,
//                               ); // ⬅ remove completely if empty
//                             } else {
//                               savedTests[testName] = {
//                                 'options': mutable,
//                                 'description':
//                                     savedTests[testName]?['description'] ?? '',
//                                 'totalAmount': _calculateTotalAmount(
//                                   test,
//                                   mutable,
//                                 ),
//                               };
//                             }
//                           });
//                         },
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 4,
//                         ),
//                         activeColor: primaryColor,
//                         title: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 name,
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             Text(
//                               "₹ $price",
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.bold,
//                                 color: primaryColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//               ),
//             );
//           }),
//
//           if (options.length > 4)
//             TextButton(
//               child: Text(
//                 showAll ? "Show Less" : "Show All",
//                 style: TextStyle(color: primaryColor),
//               ),
//               onPressed: () => setState(() => showAllMap[testName] = !showAll),
//             ),
//
//           // DESCRIPTION FIELD
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: TextField(
//               controller: descController,
//               decoration: InputDecoration(
//                 labelText: 'Description / Notes',
//                 labelStyle: TextStyle(color: primaryColor),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: primaryColor, width: 1.5),
//                 ),
//               ),
//               maxLines: 2,
//               onChanged: (value) {
//                 savedTests[testName] = {
//                   'options': savedTests[testName]?['options'] ?? <String>{},
//                   'description': value,
//                   'totalAmount': savedTests[testName]?['totalAmount'] ?? 0,
//                 };
//               },
//             ),
//           ),
//
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }
// }
