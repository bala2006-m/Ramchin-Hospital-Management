import 'package:flutter/material.dart';

import '../../../../Services/testing&scanning_service.dart';
import '../../../../Services/payment_service.dart';

class EditTestScanTab extends StatefulWidget {
  const EditTestScanTab({super.key});

  @override
  State<EditTestScanTab> createState() => _EditTestScanTabState();
}

class _EditTestScanTabState extends State<EditTestScanTab> {
  late Future<List<dynamic>> _futureData;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _originalData = [];
  List<dynamic> _filteredData = [];
  final Set<int> _deletingTestIds = {};
  final Set<String> _deletingOptionKeys = {};

  @override
  void initState() {
    super.initState();
    _futureData = _loadData();
  }

  Future<List<dynamic>> _loadData() async {
    final data = await TestingScanningService().getAllEditTestingAndScanning();
    _originalData = data;
    _filteredData = data;
    return data;
  }

  // ================= SEARCH =================
  void _onSearch(String query) {
    setState(() {
      _filteredData = query.isEmpty
          ? _originalData
          : _originalData.where((item) {
              final patient = item['Patient'];
              final name = patient?['name']?.toString().toLowerCase() ?? '';
              final pid = item['patient_Id']?.toString() ?? '';
              return name.contains(query.toLowerCase()) || pid.contains(query);
            }).toList();
    });
  }

  // ================= GROUP =================
  Map<String, List<dynamic>> _groupByConsultation(List<dynamic> data) {
    final Map<String, List<dynamic>> grouped = {};
    for (final item in data) {
      final key = '${item['patient_Id']}_${item['consultation_Id']}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }
    return grouped;
  }

  // ================= DELETE TEST =================
  Future<void> _deleteTestScan(dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Test / Scan"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletingTestIds.add(item['id']));

    try {
      await TestingScanningService().deleteTesting(item['id']);
      final List<dynamic> payments = await PaymentService().getOnePayments(
        int.parse(item['payment_Id'].toString()),
      );

      final int paymentAmount = payments.isNotEmpty
          ? int.parse(payments.first['amount'].toString())
          : 0;

      final int deleteAmount = item['amount'] ?? 0;
      final int newAmount = (paymentAmount - deleteAmount).clamp(
        0,
        paymentAmount,
      );

      await PaymentService().updatePayment(item['payment_Id'], {
        "amount": newAmount,
      });

      setState(() {
        _originalData.remove(item);
        _filteredData.remove(item);
      });
    } finally {
      setState(() => _deletingTestIds.remove(item['id']));
    }
  }

  // ================= DELETE OPTION =================

  Future<void> _deleteOption({
    required dynamic item,
    required String option,
    required int amount,
  }) async {
    final optionKey = '${item['id']}_$option';

    setState(() => _deletingOptionKeys.add(optionKey));

    final options = Map<String, dynamic>.from(
      item['selectedOptionAmounts'] ?? {},
    );
    options.remove(option);

    try {
      await TestingScanningService().updateTesting(item['id'], {
        "selectedOptionAmounts": options,
        "selectedOptions": options.keys.toList(),
        "amount": (item['amount'] ?? 0) - amount,
      });
      final List<dynamic> payments = await PaymentService().getOnePayments(
        int.parse(item['payment_Id'].toString()),
      );

      final int paymentAmount = payments.isNotEmpty
          ? int.parse(payments.first['amount'].toString())
          : 0;

      await PaymentService().updatePayment(item['payment_Id'], {
        "amount": paymentAmount - amount,
      });

      setState(() {
        item['selectedOptionAmounts'] = options;
        item['amount'] = (item['amount'] ?? 0) - amount;
      });
    } finally {
      setState(() => _deletingOptionKeys.remove(optionKey));
    }
  }

  // ================= TEST CARD =================
  Widget _testScanCard(dynamic item, int totalTestsInGroup) {
    final options = Map<String, dynamic>.from(
      item['selectedOptionAmounts'] ?? {},
    );
    final bool canDeleteTest = totalTestsInGroup > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          item['title'] ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          item['type'] ?? '',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "₹ ${item['amount'] ?? 0}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),

            _deletingTestIds.contains(item['id'])
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : canDeleteTest
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteTestScan(item),
                  )
                : const SizedBox(width: 40), // keeps UI aligned
          ],
        ),
        children: options.entries.map((e) {
          final optionKey = '${item['id']}_${e.key}';
          final bool canDeleteOption = options.length > 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade400)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(e.key, style: const TextStyle(fontSize: 14)),
                ),
                Text(
                  "₹ ${e.value}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),

                _deletingOptionKeys.contains(optionKey)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : canDeleteOption
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        onPressed: () => _deleteOption(
                          item: item,
                          option: e.key,
                          amount: e.value,
                        ),
                      )
                    : const SizedBox(width: 40, height: 40),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= PATIENT CARD =================
  Widget _patientCard(dynamic patient, int patientId, List<dynamic> items) {
    final num totalAmount = items.fold(
      0,
      (sum, item) => sum + (item['amount'] ?? 0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 22, child: Icon(Icons.person)),
              const SizedBox(width: 12),

              /// NAME + PATIENT ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient?['name'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Patient ID: $patientId",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              /// TOTAL AMOUNT
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "₹ $totalAmount",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          // ...items.map(_testScanCard),
          ...items.map((item) => _testScanCard(item, items.length)),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: "Search patient name or ID",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _futureData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_filteredData.isEmpty) {
                return const Center(child: Text("No data found"));
              }

              final grouped = _groupByConsultation(_filteredData);

              return ListView(
                padding: const EdgeInsets.all(12),
                children: grouped.entries.map((e) {
                  final items = e.value;
                  return _patientCard(
                    items.first['Patient'],
                    items.first['patient_Id'],
                    items,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
