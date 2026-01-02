import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/OutPatient/patient_registration/widget/widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../Services/Doctor/doctor_service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/patient_service.dart';
import '../../../../Services/payment_service.dart';
import '../../../../Widgets/AgeDobField.dart';
import '../../../../utils/utils.dart';
import 'scanning_page.dart';
import 'testing_page.dart';

class TestRegistration extends StatefulWidget {
  const TestRegistration({super.key});

  @override
  State<TestRegistration> createState() => TestRegistrationState();
}

class TestRegistrationState extends State<TestRegistration> {
  final consultationService = ConsultationService();
  final doctorService = DoctorService();
  final PatientService patientService = PatientService();
  final paymentService = PaymentService();
  final TextEditingController fullNameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? selectedGender;
  String? selectedBloodType;
  bool isSubmitting = false;
  bool formValidated = false;
  bool phoneValid = true;
  bool showDoctorSection = false;

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  bool isScanOpen = false;
  bool isTestOpen = false;
  bool _isSubmitting = false;

  //bool scanningTesting = false;
  final Color primaryColor = const Color(0xFFBF955E);

  String? _dateTime;

  static Map<String, Map<String, dynamic>> savedTests = {};
  static Map<String, Map<String, dynamic>> savedScans = {};
  static VoidCallback? onUpdated;
  static void onUpdate({
    Map<String, Map<String, dynamic>>? savedTest,
    Map<String, Map<String, dynamic>>? savedScan,
  }) {
    if (savedTest != null) savedTests = savedTest;
    if (savedScan != null) savedScans = savedScan;
    onUpdated?.call();
  }

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _updateTime();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('hospitalName');
    final place = prefs.getString('hospitalPlace');
    final photo = prefs.getString('hospitalPhoto');

    setState(() {
      hospitalName = name ?? "Unknown Hospital";
      hospitalPlace = place ?? "Unknown Place";
      hospitalPhoto =
          photo ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  void _submitPatientData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      DateTime dob =
          DateTime.tryParse(dobController.text) ?? DateTime(1990, 1, 1);

      String name = fullNameController.text.trim();

      // Remove existing Mr. or Ms. (case-insensitive)
      name = name.replaceFirst(
        RegExp(r'^(MR|MS)\s*\.?\s*', caseSensitive: false),
        '',
      );

      if (selectedGender.toString().toLowerCase() == 'male') {
        fullNameController.text = 'Mr. $name';
      } else if (selectedGender.toString().toLowerCase() == 'female') {
        fullNameController.text = 'Ms. $name';
      }

      final patientData = {
        "name": fullNameController.text,
        "ac_name": '',
        "staff_Id": prefs.getString('userId'),
        "phone": {"mobile": phoneController.text.trim()},
        "email": {"personal": '', "guardian": ''},
        "address": {"Address": addressController.text.trim()},
        "dob":
            '${(DateTime.parse(DateFormat('yyyy-MM-dd').format(dob))).toLocal().toIso8601String()}Z',
        "gender": selectedGender,
        "bldGrp": selectedBloodType,
        "currentProblem": '',
        "createdAt": _dateTime.toString(),
        "tempCreatedAt": DateTime.now().toUtc().toIso8601String(),
      };
      final results = await patientService.createPatient(patientData);
      if (results['status'] == 'failed' && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(results['message'])));
        return;
      }
      final patientId = await results['data']['patient']['id'];

      final hospitalId = await doctorService.getHospitalId();
      final result = await consultationService.createConsultation({
        "hospital_Id": int.parse(hospitalId),
        "patient_Id": patientId,
        "isTestOnly": true,
        "doctor_Id": prefs.getString('userId'),
        "name": '',
        "purpose": '-',
        // "emergency": isEmergency,
        // "sugarTest": isSugarTestChecked,
        // "sugerTestQueue": isSugarTestChecked,
        "temperature": 0,
        "createdAt": _dateTime.toString(),
      });
      print('result $result');

      // if (results['status'] == 'success' &&
      //     results['data'] != null &&
      //     results['data']['consultationId'] != null) {
      //   final int consultationId = results['data']['consultationId'];
      // }
      // if (result['status'] == 'failed' && mounted) {
      //   ScaffoldMessenger.of(
      //     context,
      //   ).showSnackBar(SnackBar(content: Text(result['message'])));
      //   return;
      // }
      // _submitAllScans(
      //   hospitalId: hospitalId,
      //   patientId: patientId,
      //   consultationId: consultationId,
      // );
      int? consultationId;

      if (results['status'] == 'success') {
        consultationId = results['data']['consultationId'];
        print('consultationId $consultationId');
      } else if (results['status'] == 'failed' && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(results['message'])));
        return;
      }

      // Extra safety check
      if (consultationId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consultation ID not found')),
          );
        }
        return;
      }

      _submitAllScans(
        hospitalId: hospitalId,
        patientId: patientId,
        consultationId: consultationId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient registered and created TestScan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('Error registering patient: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering patient: $e')),
        );
      }
    }
  }

  Future<void> _submitAllScans({
    required String hospitalId,
    required int patientId,
    required int consultationId,
  }) async {
    if (savedScans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No scans selected!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = prefs.getString('userId') ?? '';

      //final consultationId = widget.consultation['id'];

      for (var entry in savedScans.entries) {
        final scanName = entry.key;
        final scanData = entry.value;

        // 🔥 SKIP IF options list is empty
        if (scanData['options'] == null || scanData['options'].isEmpty) {
          continue; // Skip this scan
        }

        final payload = {
          "hospital_Id": int.parse(hospitalId),
          "patient_Id": patientId,
          "doctor_Id": doctorId,
          "consultation_Id": consultationId,
          "staff_Id": [],
          "title": scanName,
          "type": scanName,
          "reason": scanData['description'],
          "scheduleDate": DateTime.now().toIso8601String(),
          "status": "PENDING",
          "paymentStatus": false,
          "result": '',
          "amount": scanData['totalAmount'],
          "selectedOptions": scanData['options'].toList(),
          "selectedOptionAmounts": scanData['selectedOptionsAmount'],
          "createdAt": _dateTime,
        };

        await http.post(
          Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }

      final consultation = await ConsultationService().updateConsultation(
        consultationId,
        {
          'status': 'ONGOING',
          'scanningTesting': true,
          // 'medicineTonic': medicineTonicInjection,
          // 'Injection': injection,
          'queueStatus': 'COMPLETED',
          'updatedAt': _dateTime.toString(),
        },
      );
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Scan submitted!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting scans: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    onUpdated = () {
      if (mounted) {
        setState(() {});
      }
    };
    final backgroundColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final bool isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHospitalCard(
                    hospitalName: hospitalName!,
                    hospitalPlace: hospitalPlace!,
                    hospitalPhoto: hospitalPhoto!,
                  ),
                  const SizedBox(height: 18),

                  /// 🔹 MAIN FORM CARD
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 14 : 20,
                      horizontal: isMobile ? 12 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(2, 6),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isMobile ? double.infinity : 520,
                          child: buildInput(
                            "Cell No *",
                            phoneController,
                            hint: "+911234567890",
                            keyboardType: TextInputType.phone,
                            errorText: formValidatedErrorText(
                              formValidated: formValidated,
                              valid: phoneValid,
                              errMsg: 'Enter valid 10 digit number',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              IndianPhoneNumberFormatter(),
                            ],
                          ),
                        ),

                        SizedBox(
                          width: isMobile ? double.infinity : 520,
                          child: buildInput(
                            "Name *",
                            fullNameController,
                            hint: "Enter full name",
                            inputFormatters: [UpperCaseTextFormatter()],
                          ),
                        ),

                        /// 🔹 Age / DOB
                        SizedBox(
                          width: isMobile ? double.infinity : 520,
                          child: AgeDobField(
                            dobController: dobController,
                            ageController: ageController,
                          ),
                        ),

                        isTablet || isMobile
                            ? Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        sectionLabel("Gender *"),
                                        SizedBox(height: 10),
                                        Wrap(
                                          spacing: 12,
                                          children: genders
                                              .map(
                                                (e) => buildSelectionCard(
                                                  label: e,
                                                  selected: selectedGender == e,
                                                  onTap: () => setState(
                                                    () => selectedGender = e,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// 🔹 Blood Type
                                  SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        sectionLabel("Blood Type (Optional)"),
                                        SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: bloodTypes.map((type) {
                                            final selected =
                                                selectedBloodType == type;
                                            return GestureDetector(
                                              onTap: () => setState(
                                                () => selectedBloodType = type,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? customGold
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: selected
                                                        ? customGold
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  type,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: selected
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// 🔹 Gender (LEFT)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        sectionLabel("Gender *"),
                                        Wrap(
                                          spacing: 12,
                                          children: genders
                                              .map(
                                                (e) => buildSelectionCard(
                                                  label: e,
                                                  selected: selectedGender == e,
                                                  onTap: () => setState(
                                                    () => selectedGender = e,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 4),

                                  /// 🔹 Blood Type (RIGHT)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        sectionLabel("Blood Type (Optional)"),
                                        SizedBox(height: 5),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: bloodTypes.map((type) {
                                            final selected =
                                                selectedBloodType == type;
                                            return GestureDetector(
                                              onTap: () => setState(
                                                () => selectedBloodType = type,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? customGold
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: selected
                                                        ? customGold
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  type,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: selected
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                        /// 🔹 Address
                        SizedBox(
                          width: double.infinity,
                          child: buildInput(
                            "Address *",
                            addressController,
                            maxLines: 3,
                            inputFormatters: [UpperCaseTextFormatter()],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(
                              context,
                              title: 'Scans',
                              icon: Icons.document_scanner_rounded,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 12),
                            _buildActionButton(
                              context,
                              title: 'Tests',
                              icon: Icons.science_rounded,
                              color: primaryColor,
                            ),
                          ],
                        ),
                        showTestsScans(
                          savedScans: savedScans,
                          savedTests: savedTests,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// 🔹 Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () => _submitPatientData(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Text(
                              "Register Test",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (title == 'Scans') {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: ScanningPage(),
                  );
                },
              );
            }

            if (title == 'Tests') {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: TestingPage(),
                  );
                },
              );
            }
          },
          child: Column(
            children: [
              Container(
                height: 75,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),

                  /// 🌟 GOLD GRADIENT
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFCECCF), Color(0xFFF3D9AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  border: Border.all(color: Color(0xFFBF955E), width: 1.4),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: const Color(0xFF836028), size: 34),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
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
