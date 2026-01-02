import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/admin_service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/socket_service.dart';
import '../../OutPatient/Report/ReportCard.dart';
import '../../OutPatient/Report/ScanReportPage.dart';
import '../widgets/doctor_description_edit.dart';
import '../widgets/patient_histroy_in_doctor.dart';
import 'DoctorPrescriptionPage.dart';
//import 'DrOpDashboard/DrOutPatientQueuePage.dart';
import 'ScanningPage.dart';
import 'TestingPage.dart';

class PatientDescriptionPage extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final int mode; // Tests or Scan or empty
  final String role;
  const PatientDescriptionPage({
    super.key,
    required this.consultation,
    required this.mode,
    required this.role,
  });

  @override
  State<PatientDescriptionPage> createState() => _PatientDescriptionPageState();
}

class _PatientDescriptionPageState extends State<PatientDescriptionPage>
    with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFBA8C50);
  bool _showSelectedOptions = false;
  bool _isPatientExpanded = false;
  String? dateTime;
  final socketService = SocketService();

  bool scanningTesting = false;
  bool medicineTonicInjection = false;
  bool injection = false;
  bool isLoading = false; // Declare in your State class

  bool isLoadingStatus = false;
  String? logo;
  bool showTestReport = false;
  bool showScanReport = false;
  late AnimationController _controller;
  late Animation<double> expandAnimation;
  String _labName = '';
  TabController? _tabController;
  bool get isAssistantDoctor => widget.role == 'assistant doctor';
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _loadHospitalLogo();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    if (isAssistantDoctor) {
      _tabController = TabController(length: 2, vsync: this);

      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging) return;
        setState(() {
          _currentTabIndex = _tabController!.index;
        });
      });
    }
    expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.mode != 4) {
      final labId =
          widget.consultation['TeatingAndScanningPatient'][0]['staff_Id'] ?? '';

      loadNames(labId);
    }

    // async, updates state when done
  }

  Future<void> loadNames(String userId) async {
    final labProfile = await AdminService().getLabProfile(userId);

    setState(() {
      _labName = labProfile?['name'] ?? '';
    });
  }

  void _loadHospitalLogo() async {
    final prefs = await SharedPreferences.getInstance();

    logo = prefs.getString('hospitalPhoto');

    setState(() {});
  }

  void _updateTime() {
    setState(() {
      dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  bool _hasAnyVital({
    String? temperature,
    String? bloodPressure,
    String? sugar,
    String? height,
    String? weight,
    String? BMI,
    String? PK,
    String? SpO2,
  }) {
    print('sugar $sugar bb $bloodPressure');
    return _isValid(temperature) ||
        _isValid(bloodPressure) ||
        _isValid(sugar) ||
        _isValid(height) ||
        _isValid(weight) ||
        _isValid(BMI) ||
        _isValid(PK) ||
        _isValid(SpO2);
  }

  bool _isValid(String? value) {
    return value != null &&
        value.trim() != 'null' &&
        value.trim().isNotEmpty &&
        value.trim() != '0' &&
        value.trim() != 'N/A' &&
        value.trim() != '-' &&
        value.trim() != '_' &&
        value.trim() != '-mg/dL';
  }

  Future<void> _updateStatus() async {
    final consultationId = widget.consultation['id'];
    //
    if (consultationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation ID not found')),
      );
      return;
    }
    //
    try {
      setState(() {
        isLoading = true;
      });
      await ConsultationService.updateQueueStatus(consultationId, 'COMPLETED');

      setState(() {
        isLoading = false;
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  Future<void> _completedStatus() async {
    final consultationId = widget.consultation['id'];

    if (consultationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation ID not found')),
      );
      return;
    }
    //
    try {
      setState(() {
        isLoadingStatus = true;
      });
      // final consultation = await ConsultationService.updateConsultation(
      //   consultationId,
      //   {status: 'COMPLETED'},
      // );
      await ConsultationService().updateConsultation(consultationId, {
        'status': 'COMPLETED',
      });

      setState(() {
        isLoadingStatus = false;
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isLoadingStatus = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to updating status')));
      }
    }
  }

  Map<String, String> get allTestsOptionResults {
    final Map<String, String> results = {};

    final patient = widget.consultation['Patient'];
    if (patient == null) return results;

    final testingAndScanning =
        widget.consultation['TeatingAndScanningPatient'] as List<dynamic>? ??
        [];

    for (final testGroup in testingAndScanning) {
      final selectedOptions =
          testGroup['selectedOptions'] as List<dynamic>? ?? [];

      for (final opt in selectedOptions) {
        final name = opt['name']?.toString() ?? '';
        final result = (opt['result']?.toString() ?? '').trim();
        final selectedOption = opt['selectedOption']?.toString() ?? '';

        if (selectedOption == '-' || result.isEmpty) continue;

        results[name] = result;
      }
    }

    return results;
  }

  List<Map<String, dynamic>> get allTestsReportTable {
    final List<Map<String, dynamic>> formattedResults = [];

    final patient = widget.consultation['Patient'];
    if (patient == null) return formattedResults;

    final testingAndScanning =
        widget.consultation['TeatingAndScanningPatient'] as List<dynamic>? ??
        [];

    for (final testGroup in testingAndScanning) {
      final type = testGroup['type']?.toString().toLowerCase() ?? '';

      // Only handle tests, skip scans
      if (!type.contains('test')) continue;

      final String title =
          (testGroup['title']?.toString().trim().isNotEmpty ?? false)
          ? testGroup['title'].toString()
          : '-';

      final String impression =
          (testGroup['results']?.toString().trim().isNotEmpty ?? false)
          ? testGroup['results'].toString()
          : '-';

      final selectedOptions =
          testGroup['selectedOptions'] as List<dynamic>? ?? [];

      final List<Map<String, String>> results = [];

      for (final opt in selectedOptions) {
        final name = opt['name']?.toString().trim() ?? '';
        final result = opt['result']?.toString().trim() ?? '';
        final unit = opt['unit']?.toString().trim() ?? '';
        final reference = opt['reference']?.toString().trim() ?? '';
        final selectedOption = opt['selectedOption']?.toString().trim() ?? '';

        // Skip empty results or N/A
        if (selectedOption == 'N/A' || name.isEmpty || result.isEmpty) continue;

        results.add({
          'Test': name,
          'Result': result,
          'Unit': unit.isEmpty || unit == 'N/A' ? '-' : unit,
          'Range': reference.isEmpty || reference == 'N/A' ? '-' : reference,
        });
      }

      formattedResults.add({
        'title': title,
        'impression': impression,
        'results': results,
      });
    }

    return formattedResults;
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<String?> getStaffNameByUserId(String userId) async {
    final staffList = await AdminService().getMedicalStaff();

    for (final staff in staffList) {
      if (staff['user_Id'] == userId) {
        return staff['name'];
      }
    }
    return null;
  }

  // Future<void> loadNames(String userId) async {
  //   final labName = await AdminService().getLabProfile(userId);
  //
  //   setState(() {
  //     _labName = labName as String;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // Get consultation data
    final consultation = widget.consultation;
    final patient = consultation['Patient'] ?? {};
    final patientStatus = (consultation['status'] ?? '')
        .toString()
        .toLowerCase();

    // --- DOB and Age Handling ---
    final dobString = patient['dob']?.toString();
    String formattedDob = '_';
    int? age;

    if (dobString != null && dobString.isNotEmpty && dobString != 'null') {
      try {
        final dob = DateTime.parse(dobString);
        formattedDob = dob
            .toIso8601String()
            .split('T')
            .first; // e.g. "1995-06-10"
        age = _calculateAge(dob);
      } catch (e) {
        setState(() {});
      }
    }

    // --- Other patient info ---
    final name = patient['name'] ?? 'Unknown';

    final id = consultation['patient_Id'].toString();

    final complaint = consultation['purpose'] ?? '_';
    final tokenNo =
        (consultation['tokenNo'] == null || consultation['tokenNo'] == 0)
        ? '-'
        : consultation['tokenNo'].toString();
    final phone = patient['phone'] ?? '_';
    final address = patient['address']?['Address'] ?? '-';
    final gender = patient['gender'] ?? '_';
    final bloodGroup = patient['bldGrp'] ?? '_';
    final createdAt = consultation['createdAt'] ?? '';
    final doctorName = consultation['Doctor']?['name'] ?? '_';

    final temperature = consultation['temperature'].toString();
    final bloodPressure = consultation['bp'] ?? '_';
    final sugar = consultation['sugar'] ?? '_';
    final height = consultation['height'].toString() ?? '_';
    final weight = consultation['weight'].toString() ?? '_';
    final BMI = consultation['BMI'].toString() ?? '_';
    final PK = consultation['PK'].toString() ?? '_';
    final SpO2 = consultation['SPO2'].toString() ?? '_';

    // final LabId = consultation['TeatingAndScanningPatient'][0]['staff_Id'];

    // loadNames(LabId);

    // Your hospital photo base64

    // Set testing and medicine states for enabling Finished button
    final bool isButtonEnabled = scanningTesting || medicineTonicInjection;

    // Build widgets for mode 1 or 2 (Scan or Tests)
    if (widget.mode == 1 || widget.mode == 2 || widget.mode == 3) {
      return PopScope(
        canPop: false, // block default back pop
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          if (scanningTesting || medicineTonicInjection) {
            bool confirm = await _showExitConfirmation(context);
            if (confirm && context.mounted) Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: _buildAppBar(isButtonEnabled), // Extracted reusable AppBar

          body: _currentTabIndex == 0
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Show only report card and actions and button for modes 1, 2
                      if (widget.mode == 1)
                        ReportCardWidget(
                          record: widget.consultation,
                          doctorName: doctorName,

                          staffName: _labName,

                          hospitalPhotoBase64: logo ?? '',
                          optionResults: allTestsOptionResults,
                          testTable: allTestsReportTable,
                          mode: widget.mode,
                          showButtons: false,
                        ),
                      if (widget.mode == 2)
                        ScanReportCard(
                          scanData: widget.consultation,
                          hospitalLogo: logo,
                          mode: 1,
                        ),

                      if (widget.mode == 3) ...[
                        // ==========================
                        //       TEST REPORT CARD
                        // ==========================
                        _buildExpandableCard(
                          title: "Test Report",
                          icon: Icons.medical_services_rounded,
                          expanded: showTestReport,
                          onExpand: (v) => setState(() => showTestReport = v),
                          child: ReportCardWidget(
                            record: widget.consultation,
                            doctorName: doctorName,
                            staffName: _labName,
                            hospitalPhotoBase64: logo ?? '',
                            optionResults: allTestsOptionResults,
                            testTable: allTestsReportTable,
                            mode: widget.mode,
                            showButtons: false,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==========================
                        //       SCAN REPORT CARD
                        // ==========================
                        _buildExpandableCard(
                          title: "Scan Report",
                          icon: Icons.document_scanner,
                          expanded: showScanReport,
                          onExpand: (v) => setState(() => showScanReport = v),
                          child: ScanReportCard(
                            scanData: widget.consultation,
                            hospitalLogo: logo,
                            mode: 1,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade200.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.history, color: Colors.white),
                          label: const Text(
                            "View Patient History",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PatientHistoryInDoctor(patientId: id),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),
                      _buildSectionCard(
                        title: 'Consultation Actions',
                        patientStatus: patientStatus,
                        firstTest: null,
                        context: context,
                        consultation: consultation,
                      ),

                      const SizedBox(height: 12),
                      _buildExitButton(isButtonEnabled),
                      const SizedBox(height: 10),

                      _buildFinishedButton(isButtonEnabled),
                      const SizedBox(height: 30),
                    ],
                  ),
                )
              : EditTestScanTab(),
        ),
      );
    }

    // For mode 4 (normal full view)
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(isButtonEnabled),
      body: _currentTabIndex == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (patientStatus == 'endprocessing' &&
                      consultation['TeatingAndScanningPatient'] != null)
                    _buildTestResultCard(
                      (consultation['TeatingAndScanningPatient'] as List)
                              .isNotEmpty
                          ? consultation['TeatingAndScanningPatient'][0]
                          : null,
                    ),
                  const SizedBox(height: 4),
                  _buildPatientDetailsCard(
                    name: name,
                    id: id,
                    phone: phone,
                    complaint: complaint,
                    tokenNo: tokenNo,
                    address: address,
                    gender: gender,
                    dob: formattedDob,
                    age: age.toString(),
                    bloodGroup: bloodGroup,
                    createdAt: createdAt,
                  ),

                  if (_hasAnyVital(
                    temperature: temperature,
                    bloodPressure: bloodPressure,
                    sugar: sugar,
                    height: height,
                    weight: weight,
                    BMI: BMI,
                    PK: PK,
                    SpO2: SpO2,
                  ))
                    _buildVitalsDetailsCards(
                      temperature: temperature,
                      bloodPressure: bloodPressure,
                      sugar: sugar,
                      height: height,
                      weight: weight,
                      BMI: BMI,
                      PK: PK,
                      SpO2: SpO2,
                    ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.history, color: Colors.white),
                      label: const Text(
                        "View Patient History",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PatientHistoryInDoctor(patientId: id),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  _buildSectionCard(
                    title: 'Consultation Actions',
                    patientStatus: patientStatus,
                    firstTest: null,
                    context: context,
                    consultation: consultation,
                  ),

                  const SizedBox(height: 12),
                  _buildExitButton(isButtonEnabled),
                  const SizedBox(height: 10),

                  _buildFinishedButton(isButtonEnabled),

                  const SizedBox(height: 30),
                ],
              ),
            )
          : EditTestScanTab(),
    );
  }

  // Extract AppBar builder for reuse
  // Extract AppBar builder for reuse
  PreferredSizeWidget _buildAppBar(bool isButtonEnabled) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isAssistantDoctor ? 130 : 100),
      child: Column(
        children: [
          // ---- Existing AppBar UI ----
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, primaryColor]),
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
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      "Doctor Description",
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

          // ---- TABS ONLY FOR ASSISTANT DOCTOR ----
          if (isAssistantDoctor)
            Column(
              children: [
                const SizedBox(height: 8), // gap below AppBar
                TabBar(
                  controller: _tabController,
                  indicatorColor: primaryColor,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Home'),
                    Tab(text: 'Edit'),
                  ],
                ),
                const SizedBox(height: 2), // small bottom gap
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required bool expanded,
    required Function(bool) onExpand,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 0, left: 2, right: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(5, 2, 5, 10),

            // Smooth rounded shape
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),

            initiallyExpanded: expanded,
            onExpansionChanged: (v) {
              onExpand(v);
            },

            // ------------ HEADER UI ------------
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E3B7D), Color(0xFF467BD4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 24),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E3B7D),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),

            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 250),
              turns: expanded ? 0.5 : 0,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 32,
                color: Color(0xFF0E3B7D),
              ),
            ),

            // ------------ BODY CONTENT ------------
            children: [
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: child,
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),

            title: Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  "Confirm Exit",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),

            content: const Text(
              "Are you sure you want to go back?",
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.black87,
              ),
            ),

            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  foregroundColor: Colors.grey.shade700,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Yes, Exit", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Finished button builder
  Widget _buildFinishedButton(bool isButtonEnabled) {
    return ElevatedButton(
      onPressed: (isButtonEnabled && !isLoading)
          ? () async {
              setState(() => isLoading = true);
              await _updateStatus();
              setState(() => isLoading = false);
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isButtonEnabled ? Colors.green : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.greenAccent,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Text(
              'Submit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
    );
  }

  Widget _buildExitButton(bool isButtonEnabled) {
    return ElevatedButton(
      onPressed: (!isButtonEnabled && !isLoadingStatus)
          ? () async {
              setState(() => isLoadingStatus = true);
              await _completedStatus();
              setState(() => isLoadingStatus = false);
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: !isButtonEnabled ? Colors.green : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.greenAccent,
      ),
      child: isLoadingStatus
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Text(
              'Exit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
    );
  }

  // 🟢 Test Result Card
  Widget _buildTestResultCard(dynamic firstTest) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              firstTest?['title']?.toString().isNotEmpty == true
                  ? firstTest['title']
                  : "${firstTest?['type'] ?? 'UNKNOWN'}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Divider(color: Colors.grey.shade400, thickness: 1),
            Text(
              "${firstTest?['type'] ?? 'UNKNOWN'}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                child: Center(
                  child: Text(
                    (firstTest?['result'] != null &&
                            firstTest['result'].toString().isNotEmpty)
                        ? firstTest['result'].toString()
                        : 'No Result',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          (firstTest?['result'] != null &&
                              firstTest['result'].toString().isNotEmpty)
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showSelectedOptions = !_showSelectedOptions;
                });
              },
              icon: Icon(
                _showSelectedOptions ? Icons.expand_less : Icons.expand_more,
                color: Colors.blueAccent,
              ),
              label: Text(
                _showSelectedOptions
                    ? "Hide Selected Options"
                    : "View Selected Options",
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _showSelectedOptions
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (firstTest?['selectedOptions'] as List<dynamic>? ?? [])
                          .map(
                            (option) => Chip(
                              label: Text(option.toString()),
                              backgroundColor: Colors.blue.shade50,
                              side: const BorderSide(color: Colors.blueAccent),
                            ),
                          )
                          .toList(),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // 🟤 Patient Details Card
  Widget _buildPatientDetailsCard({
    required String name,
    required String id,
    required String phone,
    required String tokenNo,
    required String complaint,
    required String address,
    required String gender,
    required String dob,
    required String age,
    required String bloodGroup,
    required String createdAt,
  }) {
    IconData genderIcon;
    Color genderColor;

    switch (gender.toLowerCase()) {
      case 'male':
        genderIcon = Icons.male;
        genderColor = Colors.blue;
        break;
      case 'female':
        genderIcon = Icons.female;
        genderColor = Colors.pink;
        break;
      default:
        genderIcon = Icons.transgender;
        genderColor = Colors.purple;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isPatientExpanded = !_isPatientExpanded;
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header Row (Gender Icon + Name + Expand Icon)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: genderColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(genderIcon, color: genderColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _isPatientExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primaryColor,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(height: 8),

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
              const SizedBox(height: 3),
              Divider(color: Colors.grey.shade300),

              /// 🔹 Always Visible Info
              _infoRow("Purpose", complaint),
              _infoRow("Patient ID", id),
              _infoRow("Cell No", phone),
              _infoRow("Address", address),

              /// 🔹 Expandable Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isPatientExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300),
                    // _infoRow("Gender", gender),
                    _infoRow("Blood Group", bloodGroup),
                    _infoRow("Age", age),
                    _infoRow("DOB", dob),
                    _infoRow("Created At", createdAt),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "-",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsDetailsCards({
    String? temperature,
    String? bloodPressure,
    String? sugar,
    String? height,
    String? weight,
    String? BMI,
    String? PK,
    String? SpO2,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monitor_heart, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  "Vitals",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade400),

            /// Vitals Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_isValid(temperature))
                  _vitalTile(
                    icon: Icons.thermostat,
                    label: "Temperature",
                    value: "$temperature °F",
                  ),
                if (_isValid(bloodPressure))
                  _vitalTile(
                    icon: Icons.favorite,
                    label: "BP",
                    value: bloodPressure!,
                  ),
                if (_isValid(sugar))
                  _vitalTile(
                    icon: Icons.opacity,
                    label: "Sugar",
                    value: "$sugar mg/dL",
                  ),
                if (_isValid(weight))
                  _vitalTile(
                    icon: Icons.monitor_weight,
                    label: "Weight",
                    value: "$weight kg",
                  ),
                if (_isValid(height))
                  _vitalTile(
                    icon: Icons.height,
                    label: "Height",
                    value: "$height cm",
                  ),
                if (_isValid(BMI))
                  _vitalTile(
                    icon: Icons.calculate,
                    label: "BMI",
                    value: "$BMI BMI",
                  ),
                if (_isValid(PK))
                  _vitalTile(
                    icon: Icons.science,
                    label: "PR",
                    value: "$PK bpm",
                  ),
                if (_isValid(SpO2))
                  _vitalTile(
                    icon: Icons.monitor_heart,
                    label: "SpO₂",
                    value: "$SpO2 %",
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 10),

          /// Label (fixed width for alignment)
          SizedBox(
            width: 120,
            child: Text(
              "$label :",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          /// Value (wraps automatically)
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String patientStatus,
    required dynamic firstTest,
    required BuildContext context,
    required dynamic consultation,
  }) {
    final showOnlyPrescription =
        patientStatus == 'endprocessing' && firstTest != null;

    return Card(
      elevation: 6,
      shadowColor: primaryColor.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFBF955E), Color(0xFFD7B980)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Consultation Actions',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (showOnlyPrescription)
              Center(
                child: _buildActionButton(
                  context,
                  title: 'Prescription',
                  icon: Icons.receipt_long_rounded,
                  color: primaryColor,
                  route: DoctorsPrescriptionPage(consultation: consultation),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          title: 'Tests',
                          icon: Icons.science_rounded,
                          color: primaryColor,
                          route: TestingPage(
                            consultation: consultation,
                            testOptionName: allTestsReportTable,
                            role: widget.role,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          title: 'Scans',
                          icon: Icons.document_scanner_rounded,
                          color: primaryColor,
                          route: ScanningPage(
                            consultation: consultation,
                            role: widget.role,
                          ),
                        ),
                      ),

                      // const SizedBox(width: 15),
                      // Expanded(
                      //   child: _buildActionButton(
                      //     context,
                      //     title: 'Prescription',
                      //     icon: Icons.receipt_long_rounded,
                      //     color: primaryColor,
                      //     route: DoctorsPrescriptionPage(
                      //       consultation: consultation,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    Widget? route,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (route != null) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => route),
              );

              if (result == true) {
                setState(() => scanningTesting = true);
              } else if (result is Map<String, dynamic>) {
                final medicine = result['medicine'] == true;
                final tonic = result['tonic'] == true;
                final inject = result['injection'] == true;

                setState(() {
                  medicineTonicInjection = medicine || tonic || inject;
                  injection = inject;
                });
              }
            }
          },
          child: Column(
            children: [
              Container(
                height: 75,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),

                  /// ★ NEW GOLD GRADIENT BACKGROUND
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFCECCF), // light gold
                      const Color(0xFFF3D9AF), // deeper gold
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  /// ★ GOLD BORDER
                  border: Border.all(
                    color: const Color(0xFFBF955E),
                    width: 1.4,
                  ),

                  /// ★ SOFT SHADOW
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.15),

                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: const Color(0xFF836028), // deep gold icon
                    size: 34,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.brown.shade800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
