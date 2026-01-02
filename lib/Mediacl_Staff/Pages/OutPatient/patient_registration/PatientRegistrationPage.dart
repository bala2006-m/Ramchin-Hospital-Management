import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/OutPatient/patient_registration/test_registration.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Admin/Pages/AdminEditProfilePage.dart';
import '../../../../Services/Doctor/doctor_service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/patient_service.dart';
import '../../../../Services/payment_service.dart';
import '../../../../Widgets/AgeDobField.dart';
import './widget/widget.dart';

class PatientRegistrationPage extends StatefulWidget {
  const PatientRegistrationPage({super.key});
  @override
  State<PatientRegistrationPage> createState() =>
      _PatientRegistrationPageState();
}

class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
  final PatientService patientService = PatientService();
  final doctorService = DoctorService();
  final consultationService = ConsultationService();
  final paymentService = PaymentService();
  static int selectedIndex = 0;
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController accompanierNameController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController guardianEmailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emergencyController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController doctorIdController = TextEditingController();
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController complaintController = TextEditingController();
  final TextEditingController dataTimeController = TextEditingController();
  final TextEditingController currentProblemController =
      TextEditingController();
  final TextEditingController medicalHistoryController =
      TextEditingController();

  bool isSugarTestChecked = false;
  bool isEmergency = false;

  final TextEditingController sugarTestController = TextEditingController();

  String? _dateTime;
  String? selectedGender;
  String? selectedBloodType;
  bool showGuardianEmail = false;
  String? medicalHistoryChoice; // 'Yes' or 'No'
  bool isSubmitting = false;
  bool formValidated = false;
  bool phoneValid = true;
  bool emergencyValid = true;
  bool isLoadingDoctors = false;
  bool showDoctorSection = false;
  bool _ignorePhoneListener = false;
  List<Map<String, dynamic>> allDoctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  Map<String, dynamic>? selectedDoctor;
  List<String> filteredProblemSuggestions = [];
  List<Map<String, dynamic>> familyPatients = [];
  int? selectedPatientId; // auto-increment id
  bool isAddingNewChild = false;
  bool get hasSelectedPatient => existingPatient != null;

  // New fields for checking/existing user
  bool isExistingUser = false;
  String? lastCheckedUserId;
  bool isCheckingUser = false;
  Map<String, dynamic>? existingPatient;
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _fetchDoctors();
    currentProblemController.addListener(_filterCurrentProblemSuggestions);
    phoneController.addListener(_onPhoneControllerChanged);
    _updateTime();
    Timer.periodic(const Duration(seconds: 60), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    currentProblemController.removeListener(_filterCurrentProblemSuggestions);
    phoneController.removeListener(_onPhoneControllerChanged);
    super.dispose();
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

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  void _filterCurrentProblemSuggestions() {
    String input = currentProblemController.text.toLowerCase();
    if (input.isEmpty) {
      setState(() => filteredProblemSuggestions = []);
      return;
    }
    final filtered = currentProblemSuggestions
        .where((suggestion) => suggestion.toLowerCase().startsWith(input))
        .toList();
    setState(() => filteredProblemSuggestions = filtered);
  }

  void _onPhoneControllerChanged() {
    if (_ignorePhoneListener) return; // 🚫 skip when updating programmatically

    final raw = phoneController.text;
    String digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.startsWith('91')) digitsOnly = digitsOnly.substring(2);

    // Trigger API check when exactly 10 digits entered
    if (digitsOnly.length == 10) {
      final userId = digitsOnly;
      if (lastCheckedUserId != userId && !isCheckingUser) {
        _checkUserExists(userId);
      }
    } else {
      // Reset if user edits to <10 digits
      if (isExistingUser || existingPatient != null) {
        setState(() {
          isExistingUser = false;
          existingPatient = null;
          lastCheckedUserId = null;
          // Optional: clear other fields too
        });
      }
      setState(() => phoneValid = digitsOnly.length == 10);
    }
  }

  Future<void> _checkUserExists(String userId) async {
    setState(() {
      isCheckingUser = true;

      // 🔹 CLEAR OLD DATA IMMEDIATELY
      familyPatients = [];
      existingPatient = null;
      isExistingUser = false;
      isAddingNewChild = false;
    });

    try {
      // 🔹 Fetch patients list
      final List<Map<String, dynamic>> patients = await patientService
          .getPatientsByUserId(userId);

      if (patients.isEmpty) {
        _prepareNewPatient(userId);
        return;
      }

      if (patients.isEmpty) {
        _prepareNewPatient(userId);
        return;
      }

      lastCheckedUserId = userId;
      setState(() {
        familyPatients = patients;
        isExistingUser = true;
        isAddingNewChild = false;
      });

      if (mounted) {
        showSnackBar('Patients found. Select a patient or add new.', context);
      }
    } catch (e) {
      _prepareNewPatient(userId);
    } finally {
      if (mounted) setState(() => isCheckingUser = false);
    }
  }

  void _selectExistingPatient(Map<String, dynamic> patient) {
    final consultations = patient['Consultation'] as List<dynamic>? ?? [];

    final hasOngoing = consultations.any((c) {
      final status = c['status']?.toString().toUpperCase() ?? '';
      return status != 'COMPLETED';
    });

    if (hasOngoing && mounted) {
      showSnackBar(
        'This patient already has an ongoing consultation.',
        context,
      );
      return;
    }

    setState(() {
      existingPatient = patient;
      selectedPatientId = patient['id'];
      isAddingNewChild = false;

      fullNameController.text = patient['name'] ?? '';
      addressController.text = patient['address']?['Address'] ?? '';
      dobController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(patient['dob']));
      selectedGender = patient['gender'];
      selectedBloodType = patient['bldGrp'];
      emailController.text = patient['email']?['personal'] ?? '';
      guardianEmailController.text = patient['email']?['guardian'] ?? '';
      ageController.text = calculateAge(patient['dob']).toString();
    });
  }

  void _prepareNewPatient(String userId) {
    setState(() {
      familyPatients = [];
      existingPatient = null;
      isExistingUser = false;
      isAddingNewChild = true;

      fullNameController.clear();
      addressController.clear();
      dobController.clear();
      emailController.clear();
      guardianEmailController.clear();
      ageController.clear();
      selectedGender = null;
      selectedBloodType = null;

      _ignorePhoneListener = true;
      phoneController.text = '+91 $userId';
      _ignorePhoneListener = false;
    });

    if (mounted) showSnackBar('New patient registration', context);
  }

  Future<void> _fetchDoctors() async {
    setState(() => isLoadingDoctors = true);
    try {
      final docs = await doctorService.getDoctors();

      // 🔹 Filter Active doctors only
      final activeDoctors = docs
          .where((doc) => doc['status'] == 'ACTIVE')
          .toList();

      setState(() {
        allDoctors = activeDoctors;
        filteredDoctors = List.from(activeDoctors);
        showDoctorSection = true;
      });
    } catch (e) {
      if (mounted) showSnackBar('Error loading doctors: $e', context);
    } finally {
      setState(() => isLoadingDoctors = false);
    }
  }

  // Unified submit - behaves differently for new vs existing user
  void _submitPatient() async {
    setState(() {
      formValidated = true;

      String phoneDigits = phoneController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      if (phoneDigits.startsWith('91')) phoneDigits = phoneDigits.substring(2);
      phoneValid = phoneDigits.length == 10;
    });

    List<String> missingFields = [];
    if (fullNameController.text.trim().isEmpty) missingFields.add("Full Name");
    if (dobController.text.trim().isEmpty) missingFields.add("Date of Birth");
    if (!phoneValid) missingFields.add("Phone Number (must be 10 digits)");
    if (addressController.text.trim().isEmpty) missingFields.add("Address");
    // if (ComplaintController.text.trim().isEmpty) {
    //   missingFields.add("Current Problem");
    // }
    if (selectedGender == null) missingFields.add("Gender");
    if (doctorIdController.text.isEmpty) {
      missingFields.add("Select Doctor");
    }

    if (missingFields.isNotEmpty) {
      String msg =
          "Please fill/complete the following required fields:\n• ${missingFields.join("\n• ")}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();

    setState(() => isSubmitting = true);
    try {
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
        "ac_name": accompanierNameController.text.trim(),
        "staff_Id": prefs.getString('userId'),
        "phone": {
          "mobile": phoneController.text.trim(),
          "emergency": emergencyController.text.trim(),
        },
        "email": {
          "personal": emailController.text.trim(),
          "guardian": guardianEmailController.text.trim(),
        },
        "address": {"Address": addressController.text.trim()},
        "dob":
            '${(DateTime.parse(DateFormat('yyyy-MM-dd').format(dob))).toLocal().toIso8601String()}Z',
        "gender": selectedGender,
        "bldGrp": selectedBloodType,
        "currentProblem": currentProblemController.text.trim(),
        "createdAt": _dateTime.toString(),
        "tempCreatedAt": DateTime.now().toUtc().toIso8601String(),
      };

      // If existing user => update patient if changed, then create consultation
      if (isExistingUser) {
        // ✅ Step 1: Check existing consultations for ongoing ones
        final consultations =
            existingPatient?['Consultation'] as List<dynamic>? ?? [];

        final hasOngoing = consultations.any((c) {
          final status = c['status']?.toString().toUpperCase() ?? '';

          return status != 'COMPLETED';
        });

        if (hasOngoing && mounted) {
          showSnackBar(
            'Your consultation is already ongoing. Please complete it before creating a new one.',
            context,
          );
          setState(() => isSubmitting = false);
          return; // 🚫 stop here — do NOT create new consultation
        }

        // ✅ Step 2: Proceed normally if no ongoing consultations exist
        try {
          await patientService.updatePatient(
            selectedPatientId.toString(),
            patientData,
          );
        } catch (e) {
          if (mounted) showSnackBar('Failed to update patient: $e', context);
        }

        final hospitalId = await doctorService.getHospitalId();

        final result = await consultationService.createConsultation({
          "hospital_Id": hospitalId,
          "patient_Id": selectedPatientId,
          "doctor_Id": doctorIdController.text,
          "name": doctorNameController.text,
          "purpose": complaintController.text,
          "emergency": isEmergency,
          "sugarTest": isSugarTestChecked,
          "sugerTestQueue": isSugarTestChecked,
          "temperature": 0,
          "createdAt": _dateTime.toString(),
        });

        if (result['status'] == 'failed' && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New Appointment created')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // New user: create patient then create consultation
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
          "hospital_Id": hospitalId,
          "patient_Id": patientId,
          "doctor_Id": doctorIdController.text,
          "name": doctorNameController.text,
          "purpose": complaintController.text,
          "emergency": isEmergency,
          "sugarTest": isSugarTestChecked,
          "sugerTestQueue": isSugarTestChecked,
          "temperature": 0,
          "createdAt": _dateTime.toString(),
        });

        if (result['status'] == 'failed' && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Patient registered and created Appointment'),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register Failed, set Register fees')),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: overviewAppBar(context),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        currentIndex: selectedIndex,
        elevation: 10,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(label: "Patient", icon: Icon(Icons.people)),
          BottomNavigationBarItem(label: "Test", icon: Icon(Icons.person)),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isMobile = constraints.maxWidth < 600;
              final bool isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
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
                              /// 🔹 Emergency Toggle (Full Width)
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isEmergency
                                        ? Colors.red.shade50
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isEmergency
                                          ? Colors.red.shade400
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => setState(
                                      () => isEmergency = !isEmergency,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_rounded,
                                          color: Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            "Emergency Case",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: isEmergency,
                                          activeColor: Colors.red,
                                          onChanged: (v) =>
                                              setState(() => isEmergency = v),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              /// 🔹 Phone
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

                              /// 🔹 Family Members
                              if (familyPatients.isNotEmpty)
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildFamilySection(),
                                ),

                              /// 🔹 Name
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
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 12,
                                                children: genders
                                                    .map(
                                                      (e) => buildSelectionCard(
                                                        label: e,
                                                        selected:
                                                            selectedGender == e,
                                                        onTap: () => setState(
                                                          () => selectedGender =
                                                              e,
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
                                              sectionLabel(
                                                "Blood Type (Optional)",
                                              ),
                                              const SizedBox(height: 12),

                                              Wrap(
                                                spacing: 5,
                                                runSpacing: 10,
                                                children: bloodTypes.map((
                                                  type,
                                                ) {
                                                  final selected =
                                                      selectedBloodType == type;

                                                  return GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        selectedBloodType =
                                                            selected
                                                            ? null
                                                            : type; // ✅ toggle logic
                                                      });
                                                    },
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 18,
                                                            vertical: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: selected
                                                            ? customGold
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color: selected
                                                              ? customGold
                                                              : Colors
                                                                    .grey
                                                                    .shade300,
                                                          width: 1.2,
                                                        ),
                                                        boxShadow: selected
                                                            ? [
                                                                BoxShadow(
                                                                  color: customGold
                                                                      .withOpacity(
                                                                        0.25,
                                                                      ),
                                                                  blurRadius: 6,
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        3,
                                                                      ),
                                                                ),
                                                              ]
                                                            : [],
                                                      ),
                                                      child: Text(
                                                        type,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: selected
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),

                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// 🔹 Gender (LEFT)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              sectionLabel("Gender *"),
                                              SizedBox(height: 5),
                                              Wrap(
                                                spacing: 12,
                                                children: genders
                                                    .map(
                                                      (e) => buildSelectionCard(
                                                        label: e,
                                                        selected:
                                                            selectedGender == e,
                                                        onTap: () => setState(
                                                          () => selectedGender =
                                                              e,
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
                                              sectionLabel(
                                                "Blood Type (Optional)",
                                              ),
                                              SizedBox(height: 5),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: bloodTypes.map((
                                                  type,
                                                ) {
                                                  final selected =
                                                      selectedBloodType == type;
                                                  return GestureDetector(
                                                    onTap: () => setState(
                                                      () => selectedBloodType =
                                                          type,
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
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        border: Border.all(
                                                          color: selected
                                                              ? customGold
                                                              : Colors
                                                                    .grey
                                                                    .shade300,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        type,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
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

                              /// 🔹 Complaint
                              SizedBox(
                                width: double.infinity,
                                child: buildInput(
                                  "Chief Complaint (Optional)",
                                  complaintController,
                                ),
                              ),

                              /// 🔹 Sugar Test
                              SizedBox(
                                width: double.infinity,
                                child: _buildSugarToggle(),
                              ),

                              /// 🔹 Doctors
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sectionLabel(
                                      isExistingUser
                                          ? "Create Appointment"
                                          : "Available Doctors *",
                                    ),
                                    const SizedBox(height: 12),
                                    if (showDoctorSection) buildDoctorList(),
                                  ],
                                ),
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
                            onPressed: isSubmitting ? null : _submitPatient,
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
                                    isExistingUser
                                        ? "Create Appointment"
                                        : "Register Patient",
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
                ),
              );
            },
          ),
          TestRegistration(),
        ],
      ),
    );
  }

  Widget _buildFamilySection() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightBlue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Header
          Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.lightBlue.shade700),
              const SizedBox(width: 8),
              Text(
                "Family Members",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// 🔹 Family List
          ...familyPatients.map((p) {
            final bool isSelected =
                existingPatient != null && existingPatient!['id'] == p['id'];

            final String gender = (p['gender'] ?? '').toString();
            final int age = calculateAge(p['dob']);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.lightBlue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.lightBlue.shade300
                      : Colors.grey.shade200,
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightBlue.shade100.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),

                onTap: () => _selectExistingPatient(p),
                // onTap: () {
                //   setState(() {
                //     if (existingPatient != null &&
                //         existingPatient!['id'] == p['id']) {
                //       // 🔁 Tap again → UNSELECT
                //       existingPatient = null;
                //       _selectExistingPatient(p);
                //     } else {
                //       // ✅ Select new patient
                //       existingPatient = p;
                //     }
                //   });
                // },
                child: Row(
                  children: [
                    /// 🔹 Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.lightBlue.shade200,
                      child: Text(
                        (p['name'] ?? 'U')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    /// 🔹 Name + Meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              _chip("$age yrs", Colors.orange.shade100),
                              if (gender.isNotEmpty)
                                _chip(
                                  gender,
                                  gender.toLowerCase() == 'male'
                                      ? Colors.blue.shade100
                                      : Colors.pink.shade100,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// 🔹 Selected Icon
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Colors.lightBlue.shade600,
                        size: 26,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          /// 🔹 Add New Patient Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.person_add_alt_1,
                color: hasSelectedPatient ? Colors.grey.shade300 : Colors.white,
                size: 22,
              ),
              label: Text(
                "Add New Patient",
                style: TextStyle(
                  fontSize: 16,
                  color: hasSelectedPatient
                      ? Colors.grey.shade300
                      : Colors.white,
                ),
              ),
              onPressed: hasSelectedPatient || lastCheckedUserId == null
                  ? null // ✅ DISABLED
                  : () => _prepareNewPatient(lastCheckedUserId!),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: hasSelectedPatient
                    ? Colors
                          .grey
                          .shade400 // ✅ GREY
                    : Colors.lightBlue.shade600,
                disabledBackgroundColor:
                    Colors.grey.shade400, // ✅ explicit disabled color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Reusable Chip
  Widget _chip(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSugarToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSugarTestChecked
            ? primaryColor.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSugarTestChecked ? primaryColor : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => isSugarTestChecked = !isSugarTestChecked),
        child: Row(
          children: [
            Icon(Icons.opacity, color: primaryColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Sugar Test",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            Switch(
              value: isSugarTestChecked,
              activeColor: primaryColor,
              onChanged: (v) => setState(() => isSugarTestChecked = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDoctorList() {
    if (isLoadingDoctors) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredDoctors.isEmpty) {
      return const Text(
        'No available doctors for this complaint',
        style: TextStyle(color: customGold),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;

        int crossAxisCount;
        if (width < 600) {
          crossAxisCount = 3; // 📱 phones
        } else if (width < 900) {
          crossAxisCount = 4; // 📲 tablets
        } else if (width < 1200) {
          crossAxisCount = 5; // 💻 small web
        } else {
          crossAxisCount = 6; // 🖥️ large screens
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredDoctors.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: width < 600 ? 1.1 : 1.3,
          ),
          itemBuilder: (_, i) {
            final doc = filteredDoctors[i];
            final isSelected =
                selectedDoctor != null && selectedDoctor!['id'] == doc['id'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedDoctor = doc;
                  doctorIdController.text = doc['id'].toString();
                  doctorNameController.text = doc['name'];
                  departmentController.text = doc['department'];
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? customGold.withValues(alpha: 0.25)
                      : Colors.white,
                  border: Border.all(
                    color: customGold,
                    width: isSelected ? 2 : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: customGold.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      doc['name'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: width < 600 ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doc['department'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: customGold),
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
