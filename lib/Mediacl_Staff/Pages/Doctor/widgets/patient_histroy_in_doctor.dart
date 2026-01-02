import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../Services/consultation_service.dart';

class PatientHistoryInDoctor extends StatefulWidget {
  final String patientId;

  const PatientHistoryInDoctor({super.key, required this.patientId});

  @override
  State<PatientHistoryInDoctor> createState() => _PatientHistoryInDoctorState();
}

class _PatientHistoryInDoctorState extends State<PatientHistoryInDoctor> {
  late Future<List<dynamic>> _futureHistory;

  @override
  void initState() {
    super.initState();
    _futureHistory = _loadHistory();
  }

  Future<List<dynamic>> _loadHistory() async {
    final data = await ConsultationService().getAllConsultationsHistory(
      widget.patientId,
    );

    final filtered = data
        .where((e) => e['patient_Id'].toString() == widget.patientId)
        .toList();

    filtered.sort(
      (a, b) =>
          _parseDate(b['createdAt']).compareTo(_parseDate(a['createdAt'])),
    );

    return filtered;
  }

  // ================= HELPERS =================

  String _val(dynamic v) {
    if (v == null || v == '' || v == 0 || v == '0') return '–';
    return v.toString();
  }

  DateTime _parseDate(dynamic v) {
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime(2000);
  }

  String _formatDateTime(dynamic v) {
    final d = _parseDate(v);
    return DateFormat('dd MMM yyyy, hh:mm a').format(d);
  }

  int? _calculateAge(dynamic dob) {
    if (dob == null) return null;
    final birthDate = DateTime.tryParse(dob.toString());
    if (birthDate == null) return null;

    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // ================= HISTORY CARD =================

  Widget _historyCard(dynamic item) {
    final doctor = item['Doctor'];
    final hospital = item['Hospital'];
    final patient = item['Patient'];
    final tests = patient?['TestingAndScanning'] as List<dynamic>? ?? [];
    final age = _calculateAge(patient?['dob']);
    final purpose = _val(item['purpose'] ?? item['notes']);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        leading: const CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          patient?['name'] ?? 'Patient',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PID: ${_val(patient?['id'])}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ================= Patient Details =================
                const Text(
                  "Patient Details",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _iconText(Icons.male, _val(patient?['gender'])),
                    _iconText(Icons.bloodtype, _val(patient?['bldGrp'])),
                    if (age != null) _iconText(Icons.cake, "$age yrs"),
                    if (_val(patient?['phone']) != '–')
                      _iconText(Icons.phone, _val(patient?['phone']['mobile'])),
                    if (_val(patient?['address']) != '–')
                      _iconText(
                        Icons.location_on,
                        _val(patient?['address']?['Address']),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                if (purpose != '–')
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'purpose : $purpose',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Divider(),

                /// ================= Consultation =================
                Center(
                  child: const Text(
                    "Consultation",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor?['name'] ?? 'Doctor',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            hospital?['name'] ?? 'Hospital',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(item['status']),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Created
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Keeps row compact
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Visited On ${item['createdAt']}', // format date nicely
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ), // spacing between Created and Updated
                    // Updated
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // keeps row compact
                        children: [
                          const Icon(
                            Icons.update,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'End Date ${item['updatedAt']}',
                            // format date nicely
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),

                /// ================= Vitals =================
                const Text(
                  "Vitals",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _vitalCard("BP", item['bp']),
                    _vitalCard("Sugar", item['sugar'], unit: "mg/dL"),
                    _vitalCard("Temp", item['temperature'], unit: "°C"),
                    _vitalCard("BMI", item['BMI']),
                    _vitalCard("SPO₂", item['SPO2'], unit: "%"),
                    _vitalCard("Weight", item['weight'], unit: "kg"),
                    _vitalCard("Height", item['height'], unit: "cm"),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                /// ================= Tests / Scans =================
                const Text(
                  "Tests / Scans",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                tests.isEmpty
                    ? const Text(
                        "No tests performed",
                        style: TextStyle(color: Colors.grey),
                      )
                    : Column(children: tests.map(_testCard).toList()),

                /// ================= Notes =================
                if (_val(item['notes']) != '–') ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const Text(
                    "Notes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_val(item['notes'])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SMALL UI =================

  Widget _vitalCard(String label, dynamic value, {String? unit}) {
    final v = _val(value);
    if (v == '–') return const SizedBox.shrink();
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit != null ? "$v $unit" : v,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    if (text == '–') return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _statusChip(String? status) {
    final color = status == 'COMPLETED'
        ? Colors.green
        : status == 'PENDING'
        ? Colors.orange
        : Colors.grey;

    return Chip(
      label: Text(status ?? '–'),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }

  Widget _testCard(dynamic t) {
    final results = t['selectedOptionResults'] as Map<String, dynamic>? ?? {};
    final status = t['status']?.toString().toUpperCase() ?? "UNKNOWN";
    final statusColor = status == "COMPLETED"
        ? Colors.green
        : status == "PENDING"
        ? Colors.orange
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Status
          Row(
            children: [
              const Icon(Icons.science, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t['title'] ?? "Test",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              "Results",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Column(
              children: results.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            _val(e.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Patient History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No consultation history"));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.map(_historyCard).toList(),
          );
        },
      ),
    );
  }
}
