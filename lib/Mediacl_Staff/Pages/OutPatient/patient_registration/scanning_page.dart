import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/OutPatient/patient_registration/test_registration.dart';

import '../../../../Services/Scan_Test_Get-Service.dart';
import '../../../../Services/socket_service.dart';

class ScanningPage extends StatefulWidget {
  const ScanningPage({super.key});

  @override
  State<ScanningPage> createState() => ScanningPageState();
}

class ScanningPageState extends State<ScanningPage> {
  final Color primaryColor = const Color(0xFFBF955E);
  final socketService = SocketService();

  final ScanTestGetService _testScanService = ScanTestGetService();

  String searchQuery = "";
  final bool _isSubmitting = false;
  bool _isLoading = true;

  String? _expandedScanName;

  static final Map<String, Map<String, dynamic>> savedScans = {};
  final Map<String, bool> showAllMap = {};
  final Map<String, TextEditingController> _descControllers = {};

  List<Map<String, dynamic>> scans = [];

  @override
  void initState() {
    super.initState();
    _loadScan();
  }

  @override
  void dispose() {
    for (final c in _descControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 🔹 Fetch scans from backend
  Future<void> _loadScan() async {
    try {
      final fetchedTests = await _testScanService.fetchTests('SCAN');
      setState(() {
        scans = fetchedTests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to fetch scans: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get filteredScans {
    if (searchQuery.trim().isEmpty) return scans;
    return scans
        .where(
          (t) => t['title'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  Future<void> _submitAllScans() async {
    TestRegistrationState.onUpdate(savedScan: savedScans);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : filteredScans.isEmpty
          ? const Center(
              child: Text(
                "No scans found.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
                  for (int i = 0; i < filteredScans.length; i++)
                    _buildScanCard(filteredScans[i]),
                  const SizedBox(height: 90),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitAllScans,
        icon: const Icon(Icons.cloud_upload),
        label: _isSubmitting
            ? const Text("Submitting...")
            : const Text("Submit Scans"),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
                  "View Scanning",
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
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final scanName = scan['title'] as String;
    final options = (scan['options'] ?? []) as List<dynamic>;

    _descControllers.putIfAbsent(
      scanName,
      () => TextEditingController(
        text: savedScans[scanName]?['description'] ?? '',
      ),
    );

    final selectedAmounts = Map<String, int>.from(
      savedScans[scanName]?['amounts'] ?? {},
    );

    final bool showAll = showAllMap[scanName] ?? false;
    final displayedOptions = showAll ? options : options.take(5).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: ValueKey(scanName),
        leading: Icon(FontAwesomeIcons.vials, color: primaryColor),
        title: Center(
          child: Text(
            scanName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        initiallyExpanded: _expandedScanName == scanName,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedScanName = expanded ? scanName : null;
          });
        },
        children: [
          Divider(
            thickness: 1.5,
            color: primaryColor.withValues(alpha: 0.6),
            indent: 30,
            endIndent: 30,
          ),
          ...displayedOptions.map((opt) {
            final String name = opt['optionName'] ?? '';
            final int price = opt['price'] ?? 0;
            final bool selected = selectedAmounts.containsKey(name);

            return CheckboxListTile(
              value: selected,
              activeColor: primaryColor,
              title: Text('$name ( ₹ $price )'),
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    selectedAmounts[name] = price;
                  } else {
                    selectedAmounts.remove(name);
                  }

                  if (selectedAmounts.isEmpty) {
                    savedScans.remove(scanName);
                  } else {
                    savedScans[scanName] = {
                      'amounts': selectedAmounts,
                      'description': _descControllers[scanName]!.text,
                      'totalAmount': selectedAmounts.values.fold(
                        0,
                        (a, b) => a + b,
                      ),
                    };
                  }
                });
              },
            );
          }),
          if (options.length > 5)
            TextButton(
              onPressed: () {
                setState(() => showAllMap[scanName] = !showAll);
              },
              child: Text(
                showAll ? 'Show Less' : 'Show All',
                style: TextStyle(color: primaryColor),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _descControllers[scanName],
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter findings or notes...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (val) {
                if (savedScans.containsKey(scanName)) {
                  savedScans[scanName]!['description'] = val;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
