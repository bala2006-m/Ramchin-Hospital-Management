import 'package:flutter/material.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/OutPatient/patient_registration/test_registration.dart';

import '../../../../Services/Scan_Test_Get-Service.dart';
import '../../../../Services/socket_service.dart';

class TestingPage extends StatefulWidget {
  const TestingPage({super.key});

  @override
  State<TestingPage> createState() => TestingPageState();
}

class TestingPageState extends State<TestingPage> {
  final Color primaryColor = const Color(0xFFBF955E);
  final socketService = SocketService();

  bool _isLoading = true;
  final bool _isSubmitting = false;

  String searchQuery = "";
  int _expandedIndex = -1;

  static final Map<String, Map<String, dynamic>> savedTests = {};
  final Map<String, bool> showAllMap = {};
  final Map<String, TextEditingController> descControllers = {};

  List<Map<String, dynamic>> tests = [];
  final ScanTestGetService _testScanService = ScanTestGetService();

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  @override
  void dispose() {
    for (final c in descControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTests() async {
    try {
      final fetchedTests = await _testScanService.fetchTests('TEST');
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

  Future<void> _submitAllTests() async {
    TestRegistrationState.onUpdate(savedTest: savedTests);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
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
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                ],
              ),
            ),
          ),
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
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: "Search test name. . .",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  for (int i = 0; i < filteredTests.length; i++)
                    _buildTestCard(filteredTests[i], i),
                  const SizedBox(height: 90),
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

  Widget _buildTestCard(Map<String, dynamic> test, int index) {
    final String testName = test['title'];
    final List<dynamic> options = test['options'] ?? [];
    final bool showAll = showAllMap[testName] ?? false;

    descControllers.putIfAbsent(
      testName,
      () => TextEditingController(
        text: savedTests[testName]?['description'] ?? '',
      ),
    );

    final selectedOptionsAmount = Map<String, int>.from(
      savedTests[testName]?['selectedOptionsAmount'] ?? {},
    );

    final displayedOptions = showAll ? options : options.take(4).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: ExpansionTile(
        key: ValueKey('test_$index'),
        title: Center(
          child: Text(
            testName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        initiallyExpanded: _expandedIndex == index,
        onExpansionChanged: (v) {
          setState(() => _expandedIndex = v ? index : -1);
        },
        children: [
          ...displayedOptions.map((opt) {
            final name = opt['optionName'];
            final price = opt['price'];
            final selected = selectedOptionsAmount.containsKey(name);

            return CheckboxListTile(
              value: selected,
              activeColor: primaryColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16)),
                  Text(
                    "₹ $price",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    selectedOptionsAmount[name] = price;
                  } else {
                    selectedOptionsAmount.remove(name);
                  }

                  if (selectedOptionsAmount.isEmpty) {
                    savedTests.remove(testName);
                  } else {
                    savedTests[testName] = {
                      'options': selectedOptionsAmount.keys.toSet(),
                      'selectedOptionsAmount': selectedOptionsAmount,
                      'description': descControllers[testName]!.text,
                      'totalAmount': selectedOptionsAmount.values.fold<int>(
                        0,
                        (a, b) => a + b,
                      ),
                    };
                  }
                });
              },
            );
          }),
          if (options.length > 4)
            TextButton(
              onPressed: () => setState(() => showAllMap[testName] = !showAll),
              child: Text(
                showAll ? "Show Less" : "Show All",
                style: TextStyle(color: primaryColor),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: descControllers[testName],
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Description / Notes",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) {
                if (savedTests.containsKey(testName)) {
                  savedTests[testName]!['description'] = v;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
