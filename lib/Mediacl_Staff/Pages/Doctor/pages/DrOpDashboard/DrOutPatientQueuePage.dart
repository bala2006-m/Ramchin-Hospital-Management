import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Pages/NotificationsPage.dart';
import '../../../../../Services/admin_service.dart';
import '../../../../../Services/consultation_service.dart';
import '../../../../../Services/socket_service.dart';
import '../patient_description_page.dart';

class DrOutPatientQueuePage extends StatefulWidget {
  final String role;
  const DrOutPatientQueuePage({super.key, required this.role});

  @override
  State<DrOutPatientQueuePage> createState() => _DrOutPatientQueuePageState();
}

class _DrOutPatientQueuePageState extends State<DrOutPatientQueuePage> {
  final Color primaryColor = const Color(0xFFBF955E);
  final Color maleBorderColor = Colors.lightBlue.shade400; // Accent blue
  final Color femaleBorderColor = const Color(0xFFF48FB1); // Pink
  final Color otherBorderColor = Colors.orange.shade400;
  final socketService = SocketService();

  List<dynamic> consultations = [];
  String? doctorId;
  int selectedIndex = 0; // 0 = Pending, 1 = Ongoing
  bool isInitialLoad = true;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchConsultations(showLoading: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchConsultations(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _fetchConsultations({required bool showLoading}) async {
    if (showLoading) setState(() => isInitialLoad = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      if (widget.role == 'doctor') {
        doctorId = prefs.getString('userId');
      } else {
        final userId = prefs.getString('userId');
        final doctorData = await AdminService().getMedicalStaff();

        final matchedDoctor = doctorData.firstWhere(
          (item) => item['user_Id'] == userId,
          orElse: () => null,
        );

        doctorId = matchedDoctor?['assignDoctorId'];
      }
      // widget.role == 'doctor'
      //     ?
      //     :  final staffData = await AdminService().getMedicalStaff();;

      final allConsultations = await ConsultationService()
          .getAllDrConsultationDrQueue(doctorId: doctorId);

      if (mounted) {
        setState(() {
          consultations = allConsultations;
          isInitialLoad = false;
        });
      }
    } on SocketException {
      if (showLoading && mounted) setState(() => isInitialLoad = false);
    } catch (_) {
      if (showLoading && mounted) setState(() => isInitialLoad = false);
    }
  }

  List<dynamic> _filteredConsultations() {
    if (selectedIndex == 0) {
      return consultations.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
        return (status == 'pending' || status == 'endprocessing') &&
            queueStatus == 'drqueue';
      }).toList();
    } else if (selectedIndex == 1) {
      return consultations.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
        return (status == 'pending' || status == 'endprocessing') &&
            queueStatus == 'ongoing';
      }).toList();
    }
    return consultations;
  }

  Color _getBorderColor(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
      case 'm':
        return maleBorderColor;
      case 'female':
      case 'f':
        return femaleBorderColor;
      default:
        return otherBorderColor;
    }
  }

  IconData _getGenderIcon(String? gender) {
    switch ((gender ?? "").toLowerCase()) {
      case 'male':
      case 'm':
        return Icons.male;
      case 'female':
      case 'f':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  Color _getGenderIconColor(String? gender) {
    switch ((gender ?? "").toLowerCase()) {
      case 'male':
      case 'm':
        return maleBorderColor;
      case 'female':
      case 'f':
        return femaleBorderColor;
      default:
        return otherBorderColor;
    }
  }

  int getModeFromType(dynamic list) {
    if (list == null || list is! List || list.isEmpty) return 4;

    bool hasTest = false;
    bool hasScan = false;

    for (var item in list) {
      final type = (item['type'] ?? '').toString().toLowerCase();

      if (type.contains('tests')) hasTest = true;
      if (type.contains('x-ray') ||
          type.contains('ct-scan') ||
          type.contains('pet scan') ||
          type.contains('mri-scan') ||
          type.contains('ultrasound') ||
          type.contains('ecg') ||
          type.contains('eeg')) {
        hasScan = true;
      }
    }

    if (hasTest && hasScan) return 3; // Both Test + Scan
    if (hasTest) return 1; // Only Test
    if (hasScan) return 2; // Only Scan
    return 4; // Default
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> consultation) {
    print('consultation $consultation');
    final patient = consultation['Patient'] ?? {};
    final name = patient['name'] ?? 'Unknown';
    final tokenNo =
        (consultation['tokenNo'] == null || consultation['tokenNo'] == 0)
        ? '-'
        : consultation['tokenNo'].toString();
    final id = consultation['patient_Id'].toString();

    final phone = patient['phone'] ?? '-';
    final address = patient['address']?['Address'] ?? '-';
    final gender = patient['gender'] ?? '';
    // final status = (consultation['status'] ?? 'Unknown').toString();
    final testingAndScanning = consultation['TeatingAndScanningPatient'];
    final type =
        (testingAndScanning is List &&
            testingAndScanning.isNotEmpty &&
            testingAndScanning[0]['type'] != null)
        ? (testingAndScanning[0]['type'])
        : '';

    // final mode = getModeFromType(type);
    final mode = getModeFromType(consultation['TeatingAndScanningPatient']);

    return GestureDetector(
      onTap: () async {
        final currentQueueStatus = (consultation['queueStatus'] ?? "")
            .toString()
            .toLowerCase();

        // 🔥 Only update the first time (Pending → Ongoing)
        if (currentQueueStatus == 'drqueue' ||
            currentQueueStatus == 'DRQUEUE') {
          await ConsultationService.updateQueueStatus(
            consultation['id'],
            'ONGOING',
          );
        }

        dynamic result;
        if (mounted) {
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDescriptionPage(
                consultation: consultation,
                mode: mode,
                role: widget.role,
              ),
            ),
          );
        }
        // await ConsultationService.updateQueueStatus(
        //   consultation['id'],
        //   'ONGOING',
        // );

        _fetchConsultations(showLoading: false);
        // If result returned TRUE → refresh again with loading
        if (result == true) {
          _fetchConsultations(showLoading: true);
        }
      },

      child: Card(
        color: type.toString().isEmpty
            ? Colors.white
            : Colors.lightGreen.shade50, // change card color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: type.toString().isEmpty
              ? BorderSide(color: _getBorderColor(gender), width: 2)
              : BorderSide.none,
        ),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getGenderIcon(gender),
                    color: _getGenderIconColor(gender),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (type.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Chip(
                        label: Text(
                          mode == 1
                              ? "Test"
                              : mode == 2
                              ? "Scan"
                              : mode == 3
                              ? "Test_Scan"
                              : "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),
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
              const SizedBox(height: 6),

              _buildInfoRow("Patient ID:", id),
              _buildInfoRow("Cell No:", phone),
              _buildInfoRow("Address:", address),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({String message = "No patients in queue"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/Lottie/NoData.json', width: 280, height: 280),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                color: Colors.black.withValues(alpha: 0.2),
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
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                  ),

                  const Text(
                    "Outpatient Queue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.group_rounded, color: Colors.white),
                    tooltip: "Show All Patients",
                    onPressed: () => setState(() => selectedIndex = 0),
                  ),
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
      body: isInitialLoad
          ? const Center(child: CircularProgressIndicator())
          : consultations.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_rounded, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        selectedIndex == 0
                            ? "Pending Patients"
                            : "Consulting Patients",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "( ${_filteredConsultations().length} )",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: primaryColor,
                    onRefresh: () => _fetchConsultations(showLoading: false),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      itemCount: _filteredConsultations().length,
                      itemBuilder: (context, index) {
                        final consultation = _filteredConsultations()[index];
                        return _buildPatientCard(
                          Map<String, dynamic>.from(consultation),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryColor,
        currentIndex: selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Pending'),
          BottomNavigationBarItem(
            icon: Icon(Icons.run_circle_outlined),
            label: 'Consulting',
          ),
        ],
      ),
    );
  }
}
